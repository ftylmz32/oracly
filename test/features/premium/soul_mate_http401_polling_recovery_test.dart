/// WAVE 2.3 — SoulMate steady-state durable polling vs HTTP 401 (RED gate).
///
/// The screen is already observing a processing DURABLE operation. One poll
/// of `/v1/reading-flow/active` fails, then auth/connectivity is back and the
/// durable worker finishes the SAME operation. Whatever the transient
/// failure (no wire, 503, 429, 401), the screen must keep polling that
/// operation and show its result — never strand the user on the drawing
/// spinner, never create a second operation.
///
/// Same harness as soul_mate_startup_durable_collision_test.dart. Production
/// code unchanged.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/ai/production/ai_request_fingerprint.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_waiting.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/soul_mate_generation_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_generation_policy.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_input_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';
import '../../support/test_path_provider.dart';

/// Marker for "no wire at all" (transport failure) in [_Transport.script].
const _noWire = -1;

/// Transport in front of the fake server. Each queued [script] entry
/// answers the next `/active` GET instead of the server ([_noWire] or an
/// HTTP error status); an empty script passes everything through.
class _Transport {
  _Transport(this.server);
  final FakeReadingOperationBackend server;
  final List<int> script = [];
  int activeCalls = 0;
  final List<Map<String, Object>> creates = [];

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (method == 'GET' && path.startsWith('/v1/reading-flow/active')) {
      activeCalls++;
      if (script.isNotEmpty) {
        final status = script.removeAt(0);
        if (status == _noWire) return null;
        return ReadingOperationWire(
          statusCode: status,
          json: {
            'success': false,
            'error': {'code': status == 401 ? 'unauthorized' : 'unavailable'},
          },
        );
      }
    }
    if (method == 'POST' && path == '/v1/reading-operations') {
      creates.add({...?body});
    }
    return server.send(method, path, body);
  }

  ReadingFeatureRunner runner() => ReadingFeatureRunner(
        serverOwnedCompletion: false,
        inputs: ReadingOperationInputGateway(send: send),
        flow: ReadingLiveFlow(
          operations: ReadingOperationGateway(send: send),
          acceleration: ReadingAccelerationClient(send: send),
          send: send,
        ),
      );
}

const _png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

const _source = 'durable-polling-soulmate-01aaaaaaaaaaaaaaaaaaaa';

Future<LocalStorage> _premiumStorage({String owner = 'user-a'}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await storage.setString(UserLocalDataIsolation.ownerKey, owner);
  PremiumDevOverride.debugEnvironment = AppEnvironment.development;
  PremiumDevOverride.debugFlag = true;
  await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);
  return storage;
}

Future<String> _seedDurableProcessing(FakeReadingOperationBackend server) async {
  final created = await server.send('POST', '/v1/reading-operations', {
    'readingType': 'soulmate',
    'sourceRequestId': _source,
    'language': 'tr',
    'executionMode': 'durable',
  });
  final id = (created!.json!['data'] as Map)['operationId'] as String;
  await server.send('POST', '/v1/reading-operations/$id/input', {
    'name': 'Ada',
    'birthIso': '1995-03-02',
  });
  await server.send('POST', '/v1/reading-operations/$id/claim', const {});
  return id;
}

void _completeOnServer(FakeReadingOperationBackend server, String id) {
  server.setSoulmatePortrait(id, imageBase64: base64Encode(_png));
  server.completeServerSide(
    id,
    resultId: 'soulmate_$id',
    result: const {
      'personality': 'p',
      'dynamic': 'd',
      'attraction': 'a',
      'challenge': 'c',
      'meeting': 'm',
      'feeling': 'f',
    },
  );
}

Future<void> _open(
  WidgetTester tester,
  LocalStorage storage,
  _Transport transport,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        readingFeatureRunnerProvider.overrideWithValue(transport.runner()),
        readingOperationInputGatewayProvider.overrideWithValue(
          ReadingOperationInputGateway(send: transport.send),
        ),
      ],
      child: const MaterialApp(home: SoulMateDrawScreen()),
    ),
  );
  await tester.pump();
  final element = tester.element(find.byType(SoulMateDrawScreen));
  await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _settleRealIo(WidgetTester tester) => tester.runAsync(() async {
      for (var i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    });

const _pollInterval = Duration(seconds: 3);

/// Observing a processing durable op → one poll answered by [failure] →
/// auth/connectivity restored and the SAME op completes server-side.
Future<void> _steadyStateFailureThenRecovery(
  WidgetTester tester,
  int failure,
  String label,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final storage = await _premiumStorage();
  final server = FakeReadingOperationBackend();
  final id = await _seedDurableProcessing(server);
  final transport = _Transport(server);

  await _open(tester, storage, transport);
  expect(find.byType(SoulMateDrawWaiting), findsOneWidget,
      reason: 'precondition: observing the processing durable operation');
  final beforeFailure = transport.activeCalls;

  transport.script.add(failure);
  await tester.pump(_pollInterval);
  await tester.pump();
  final afterFailure = transport.activeCalls;
  final stillDrawing = find.byType(SoulMateDrawWaiting).evaluate().isNotEmpty;

  // Auth / connectivity restored; the durable worker finishes the SAME op.
  _completeOnServer(server, id);
  await tester.pump(_pollInterval);
  await tester.pump();
  final afterNextInterval = transport.activeCalls;
  await tester.pump(_pollInterval);
  await _settleRealIo(tester);
  await tester.pump(const Duration(milliseconds: 100));
  final afterSixSeconds = transport.activeCalls;

  final metrics = '$label polls: before=$beforeFailure '
      'afterFailure=$afterFailure +3s=$afterNextInterval '
      '+6s=$afterSixSeconds; drawingAfterFailure=$stillDrawing; '
      'drawingNow=${find.byType(SoulMateDrawWaiting).evaluate().isNotEmpty}; '
      'resultShown=${find.text(SoulMateCopy.redrawCta).evaluate().isNotEmpty}; '
      'creates=${transport.creates.length}; ops=${server.operationCount}';

  expect(afterFailure, beforeFailure + 1, reason: 'failure poll ran. $metrics');
  expect(stillDrawing, isTrue,
      reason: 'a transient poll failure is not a final verdict. $metrics');
  expect(afterNextInterval, greaterThan(afterFailure),
      reason: 'polling must continue after the failure. $metrics');
  expect(find.text(SoulMateCopy.redrawCta), findsOneWidget,
      reason: 'result of the same operation must arrive. $metrics');
  expect(find.byType(SoulMateDrawWaiting), findsNothing,
      reason: 'no endless spinner. $metrics');
  expect((await SoulMateResultStore.readMeta(storage))?.id, id,
      reason: 'same operation id. $metrics');
  expect(transport.creates, isEmpty, reason: 'no new submit. $metrics');
  expect(server.operationCount, 1, reason: 'no duplicate op. $metrics');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(PremiumDevOverride.resetDebug);

  late Directory temp;
  setUp(() async {
    temp = await installTestPathProvider('soulmate_401_');
  });
  tearDown(() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (await temp.exists()) await temp.delete(recursive: true);
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  testWidgets(
    'D. HTTP 401 during steady-state polling: keeps polling the same '
    'operation and shows its result once auth is restored (H: no new create)',
    (tester) => _steadyStateFailureThenRecovery(tester, 401, 'HTTP401'),
  );

  group('guards — existing transient contract', () {
    testWidgets(
      'A. transport failure (no wire) keeps polling and recovers',
      (tester) => _steadyStateFailureThenRecovery(tester, _noWire, 'noWire'),
    );
    testWidgets(
      'B. HTTP 503 keeps polling and recovers',
      (tester) => _steadyStateFailureThenRecovery(tester, 503, 'HTTP503'),
    );
    testWidgets(
      'C. HTTP 429 keeps polling and recovers',
      (tester) => _steadyStateFailureThenRecovery(tester, 429, 'HTTP429'),
    );
  });

  group('guards — permanent 401 safety', () {
    testWidgets(
      'PERMANENT 401: bounded retries, no endless spinner or request loop, '
      'honest recoverable error, operation preserved and recoverable on reopen',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final id = await _seedDurableProcessing(server);
        final transport = _Transport(server);
        await _open(tester, storage, transport);
        final before = transport.activeCalls;

        transport.script.addAll(List.filled(50, 401));
        for (var i = 0; i < 12; i++) {
          await tester.pump(_pollInterval);
          await tester.pump();
        }
        final polls401 = transport.activeCalls - before;

        expect(polls401, 4,
            reason: 'first 401 + exactly 3 bounded retries, then stop');
        expect(find.byType(SoulMateDrawWaiting), findsNothing,
            reason: 'no endless spinner');
        expect(find.text(SoulMateCopy.failureTemporary), findsOneWidget,
            reason: 'honest, recoverable error');
        expect(find.text(SoulMateCopy.retry), findsOneWidget);
        expect(transport.creates, isEmpty);
        expect(server.operationCount, 1);
        final stillThere = await server.send(
          'GET',
          '/v1/reading-operations/$id',
          null,
        );
        expect((stillThere?.json?['data'] as Map?)?['status'], 'processing',
            reason: 'the operation is untouched server-side');

        // Later, auth is fine again and the worker finished: reopening the
        // screen recovers the SAME operation — no new submit.
        transport.script.clear();
        _completeOnServer(server, id);
        await tester.pumpWidget(const SizedBox());
        await _open(tester, storage, transport);
        await _settleRealIo(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
        expect((await SoulMateResultStore.readMeta(storage))?.id, id);
        expect(transport.creates, isEmpty);
        expect(server.operationCount, 1);
      },
    );

    testWidgets(
      'owner change during 401 retries stops observing without showing the '
      "previous owner's state",
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        await _seedDurableProcessing(server);
        final transport = _Transport(server);
        await _open(tester, storage, transport);

        transport.script.addAll(List.filled(50, 401));
        await tester.pump(_pollInterval);
        await tester.pump();
        await storage.setString(UserLocalDataIsolation.ownerKey, 'user-b');
        await tester.pump(_pollInterval);
        await tester.pump();
        final atStop = transport.activeCalls;
        await tester.pump(_pollInterval * 4);

        expect(transport.activeCalls, atStop, reason: 'polling stopped');
        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect(find.text(SoulMateCopy.failureTemporary), findsNothing);
        expect(transport.creates, isEmpty);
      },
    );
  });

  group('guards — terminal outcomes', () {
    testWidgets(
      'E. definitive durable FAILED: polling stops and an error is shown',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final id = await _seedDurableProcessing(server);
        final transport = _Transport(server);
        await _open(tester, storage, transport);
        expect(find.byType(SoulMateDrawWaiting), findsOneWidget);

        await server.send(
          'POST',
          '/v1/reading-operations/$id/fail',
          const {'stage': 'provider'},
        );
        await tester.pump(_pollInterval);
        await tester.pump();
        final atFailed = transport.activeCalls;
        await tester.pump(_pollInterval * 3);

        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect(find.text(SoulMateCopy.failureTemporary), findsOneWidget);
        expect(transport.activeCalls, atFailed, reason: 'polling stopped');
        expect(transport.creates, isEmpty);
      },
    );

    testWidgets(
      'F. READY: result exactly once and polling stops',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final id = await _seedDurableProcessing(server);
        final transport = _Transport(server);
        await _open(tester, storage, transport);

        _completeOnServer(server, id);
        await tester.pump(_pollInterval);
        await _settleRealIo(tester);
        await tester.pump(const Duration(milliseconds: 100));
        final atReady = transport.activeCalls;
        await tester.pump(_pollInterval * 3);

        expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect((await SoulMateResultStore.readMeta(storage))?.id, id);
        expect(transport.activeCalls, atReady, reason: 'polling stopped');
        expect(transport.creates, isEmpty);
        expect(server.operationCount, 1);
      },
    );
  });

  testWidgets(
    'G. owner isolation: a 401 for user-b never attaches user-b to user-a\'s '
    'operation, identity or result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage(owner: 'user-b');
      // user-a's in-flight identity is still on this device.
      await SoulMateGenerationIdentity.write(
        storage,
        ownerId: 'user-a',
        logicalId: _source,
        fingerprint: AiRequestFingerprint.soulMate(
          name: 'Ada',
          birthDate: '1995-03-02',
        ),
        phase: SoulMateGenerationPhase.generating,
        name: 'Ada',
        birthIso: '1995-03-02',
      );
      final serverB = FakeReadingOperationBackend();
      final transport = _Transport(serverB)..script.add(401);

      await _open(tester, storage, transport);
      await tester.pump(_pollInterval * 2);

      expect(find.byType(SoulMateDrawWaiting), findsNothing);
      expect(find.text(SoulMateCopy.redrawCta), findsNothing);
      expect(await SoulMateResultStore.readMeta(storage), isNull);
      expect(transport.creates, isEmpty);
      expect(serverB.operationCount, 0);
    },
  );
}
