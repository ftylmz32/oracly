/// WAVE 2.1 — SoulMate startup durable/legacy collision (RED gate).
///
/// A DURABLE SoulMate operation is processing server-side. The screen opens;
/// the first `/v1/reading-flow/active` (recoverDurable) is transiently
/// unreachable, the connection comes back for the next call. That
/// operation must keep being observed: never shown as a stale legacy
/// failure, never re-submitted as a brand-new operation (duplicate
/// portrait). Real legacy, no-active, ready, exact-target and owner
/// behaviour must stay as they are.
///
/// Same widget harness as soul_mate_durable_test.dart; only the transport in
/// front of the fake server is scripted. Production code unchanged.
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
import 'package:oracly_new/features/premium/services/soul_mate_generation_session.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_input_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';
import '../../support/test_path_provider.dart';

/// Transport in front of the fake server: the next [unreachableActive]
/// `/active` GETs get no wire (transport failure); everything else passes
/// through. Every operation create is recorded.
class _Transport {
  _Transport(this.server);
  final FakeReadingOperationBackend server;
  int unreachableActive = 0;
  int activeCalls = 0;
  final List<Map<String, Object>> creates = [];

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    if (method == 'GET' && path.startsWith('/v1/reading-flow/active')) {
      activeCalls++;
      if (unreachableActive > 0) {
        unreachableActive--;
        return null;
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

const _inflightSource = 'durable-inflight-soulmate-01aaaaaaaaaaaaaaaaaaa';
const _name = 'Ada';
const _birthIso = '1995-03-02';

Future<LocalStorage> _premiumStorage({String owner = 'user-a'}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await storage.setString(UserLocalDataIsolation.ownerKey, owner);
  PremiumDevOverride.debugEnvironment = AppEnvironment.development;
  PremiumDevOverride.debugFlag = true;
  await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);
  return storage;
}

/// Server-side: one operation for this owner, processing (claimed).
Future<String> _seedProcessing(
  FakeReadingOperationBackend server, {
  required String source,
  required bool durable,
}) async {
  final created = await server.send('POST', '/v1/reading-operations', {
    'readingType': 'soulmate',
    'sourceRequestId': source,
    'language': 'tr',
    if (durable) 'executionMode': 'durable',
  });
  final id = (created!.json!['data'] as Map)['operationId'] as String;
  await server.send('POST', '/v1/reading-operations/$id/input', {
    'name': _name,
    'birthIso': _birthIso,
  });
  await server.send('POST', '/v1/reading-operations/$id/claim', const {});
  return id;
}

/// Client-side: this device submitted [source] for [owner] (in flight).
Future<void> _seedLocalIdentity(
  LocalStorage storage, {
  required String owner,
  required String source,
}) =>
    SoulMateGenerationIdentity.write(
      storage,
      ownerId: owner,
      logicalId: source,
      fingerprint: AiRequestFingerprint.soulMate(
        name: _name,
        birthDate: _birthIso,
      ),
      phase: SoulMateGenerationPhase.generating,
      name: _name,
      birthIso: _birthIso,
    );

Widget _screen(
  LocalStorage storage,
  _Transport transport, {
  String? operationId,
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      readingFeatureRunnerProvider.overrideWithValue(transport.runner()),
      readingOperationInputGatewayProvider.overrideWithValue(
        ReadingOperationInputGateway(send: transport.send),
      ),
    ],
    child: MaterialApp(home: SoulMateDrawScreen(operationId: operationId)),
  );
}

Future<void> _open(
  WidgetTester tester,
  LocalStorage storage,
  _Transport transport, {
  String? operationId,
}) async {
  await tester.pumpWidget(_screen(storage, transport, operationId: operationId));
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

String _describe(List<Map<String, Object>> creates) => creates
    .map((c) => '{type: ${c['readingType']}, source: ${c['sourceRequestId']}, '
        'mode: ${c['executionMode']}}')
    .join(', ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(PremiumDevOverride.resetDebug);

  late Directory temp;
  setUp(() async {
    temp = await installTestPathProvider('soulmate_collision_');
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

  group('STARTUP COLLISION — durable processing + transient first recover', () {
    testWidgets(
      'keeps observing the same durable operation: no stale-legacy failure, '
      'no retry offer',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final durableId = await _seedProcessing(
          server,
          source: _inflightSource,
          durable: true,
        );
        await _seedLocalIdentity(storage, owner: 'user-a', source: _inflightSource);
        final transport = _Transport(server)..unreachableActive = 1;

        await _open(tester, storage, transport);

        expect(transport.activeCalls, greaterThanOrEqualTo(2),
            reason: 'call 1 (recoverDurable) unreachable, call 2 answered');
        expect(server.operationCount, 1);
        expect(find.text(SoulMateCopy.failureUnavailable), findsNothing,
            reason: 'durable $durableId is processing, not a stale legacy '
                'record — no false failure');
        expect(find.text(SoulMateCopy.retry), findsNothing,
            reason: 'nothing failed; a retry here would start a 2nd portrait');
        expect(find.byType(SoulMateDrawWaiting), findsOneWidget,
            reason: 'the same durable operation must keep being observed');
        expect(transport.creates, isEmpty);
      },
    );

    testWidgets(
      'never creates a second SoulMate operation (duplicate portrait) for '
      'the in-flight durable one',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        await _seedProcessing(server, source: _inflightSource, durable: true);
        await _seedLocalIdentity(storage, owner: 'user-a', source: _inflightSource);
        final transport = _Transport(server)..unreachableActive = 1;

        await _open(tester, storage, transport);
        expect(server.operationCount, 1, reason: 'initial durable ops');

        // Whatever the screen offers, the user takes it.
        final retry = find.text(SoulMateCopy.retry);
        if (retry.evaluate().isNotEmpty) {
          await tester.tap(retry);
          await tester.pump();
        }

        expect(transport.creates, isEmpty,
            reason: 'creates after startup: ${_describe(transport.creates)} '
                '(in-flight source: $_inflightSource); server SoulMate '
                'operations now: ${server.operationCount}');
        expect(server.operationCount, 1,
            reason: 'exactly one SoulMate operation for this owner');
      },
    );
  });

  testWidgets(
    'POLLING CONTINUITY + F. same durable identity: after the transient '
    'start the SAME operation is polled to ready and shown exactly once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final server = FakeReadingOperationBackend();
      final durableId = await _seedProcessing(
        server,
        source: _inflightSource,
        durable: true,
      );
      await _seedLocalIdentity(storage, owner: 'user-a', source: _inflightSource);
      final transport = _Transport(server)..unreachableActive = 1;

      await _open(tester, storage, transport);
      expect(find.byType(SoulMateDrawWaiting), findsOneWidget);
      final callsAfterStart = transport.activeCalls;

      // Still processing at the next poll: keeps observing, no error.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(transport.activeCalls, greaterThan(callsAfterStart),
          reason: 'the durable operation is polled again');
      expect(find.byType(SoulMateDrawWaiting), findsOneWidget);
      expect(find.text(SoulMateCopy.failureUnavailable), findsNothing);

      // The durable worker finishes the ORIGINAL operation.
      server.setSoulmatePortrait(durableId, imageBase64: base64Encode(_png));
      server.completeServerSide(
        durableId,
        resultId: 'soulmate_$durableId',
        result: const {
          'personality': 'p',
          'dynamic': 'd',
          'attraction': 'a',
          'challenge': 'c',
          'meeting': 'm',
          'feeling': 'f',
        },
      );
      await tester.pump(const Duration(seconds: 3));
      await _settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SoulMateDrawWaiting), findsNothing,
          reason: 'no endless spinner once ready');
      expect(find.text(SoulMateCopy.redrawCta), findsOneWidget,
          reason: 'result rendered exactly once');
      expect((await SoulMateResultStore.readMeta(storage))?.id, durableId,
          reason: 'original operation id preserved');
      expect(
        (await SoulMateGenerationSessionStore.readForOwner(storage, 'user-a'))
            ?.logicalId,
        _inflightSource,
        reason: 'original sourceRequestId preserved',
      );
      expect(transport.creates, isEmpty);
      expect(server.operationCount, 1);

      // Nothing else polls after ready.
      final callsAtReady = transport.activeCalls;
      await tester.pump(const Duration(seconds: 7));
      expect(transport.activeCalls, callsAtReady);
    },
  );

  group('guards', () {
    testWidgets(
      'A. REAL legacy processing (no executionMode), even after a transient '
      'first recover: controlled stale-legacy retry starts ONE new durable op',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        await _seedProcessing(
          server,
          source: 'legacy-stuck-01aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          durable: false,
        );
        final transport = _Transport(server)..unreachableActive = 1;

        await _open(tester, storage, transport);

        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect(find.text(SoulMateCopy.retry), findsOneWidget);
        expect(server.operationCount, 1);

        await tester.tap(find.text(SoulMateCopy.retry));
        await tester.pump();

        expect(server.operationCount, 2);
        expect(transport.creates, hasLength(1));
        expect(transport.creates.single['executionMode'], 'durable');
      },
    );

    testWidgets(
      'B. transient first recover + NO active operation: no error, no '
      'attachment, nothing created',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final transport = _Transport(server)..unreachableActive = 1;

        await _open(tester, storage, transport);

        expect(find.text(SoulMateCopy.failureUnavailable), findsNothing);
        expect(find.text(SoulMateCopy.retry), findsNothing);
        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
        expect(transport.creates, isEmpty);
        expect(server.operationCount, 0);
      },
    );

    testWidgets(
      'C. durable READY on open: result rendered once, no new draw',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final id = await _seedProcessing(
          server,
          source: _inflightSource,
          durable: true,
        );
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
        final transport = _Transport(server);

        await _open(tester, storage, transport);
        await _settleRealIo(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect((await SoulMateResultStore.readMeta(storage))?.id, id);
        expect(transport.creates, isEmpty);
        expect(server.operationCount, 1);
      },
    );

    testWidgets(
      'D. exact deep-link target attaches to THAT operation only, never to '
      'another active one, and creates nothing',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final storage = await _premiumStorage();
        final server = FakeReadingOperationBackend();
        final targetId = await _seedProcessing(
          server,
          source: 'push-target-soulmate-01aaaaaaaaaaaaaaaaaaaaaaaa',
          durable: true,
        );
        server.setSoulmatePortrait(targetId, imageBase64: base64Encode(_png));
        server.completeServerSide(
          targetId,
          resultId: 'soulmate_$targetId',
          result: const {
            'personality': 'tp',
            'dynamic': 'td',
            'attraction': 'ta',
            'challenge': 'tc',
            'meeting': 'tm',
            'feeling': 'tf',
          },
        );
        await _seedProcessing(
          server,
          source: 'other-active-soulmate-01aaaaaaaaaaaaaaaaaaaaaaa',
          durable: true,
        );
        final transport = _Transport(server);

        await _open(tester, storage, transport, operationId: targetId);
        await _settleRealIo(tester);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
        expect((await SoulMateResultStore.readMeta(storage))?.id, targetId);
        expect(transport.activeCalls, 0,
            reason: 'exact target never consults the feature-wide pointer');
        expect(transport.creates, isEmpty);
        expect(server.operationCount, 2);
      },
    );

    testWidgets(
      'E. owner isolation: user-a\'s in-flight identity never becomes '
      'user-b\'s, and user-b attaches to nothing of user-a',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        // Same device storage, now owned by user-b; user-a's journal record
        // is still present. user-b's server has no SoulMate operation.
        final storage = await _premiumStorage(owner: 'user-b');
        await _seedLocalIdentity(storage, owner: 'user-a', source: _inflightSource);
        final serverB = FakeReadingOperationBackend();
        final transport = _Transport(serverB)..unreachableActive = 1;

        await _open(tester, storage, transport);

        expect(find.byType(SoulMateDrawWaiting), findsNothing);
        expect(find.text(SoulMateCopy.retry), findsNothing);
        expect(transport.creates, isEmpty);
        expect(serverB.operationCount, 0);
        expect(
          await SoulMateGenerationSessionStore.readForOwner(storage, 'user-b'),
          isNull,
        );
        final bLogicalId = await SoulMateGenerationIdentity.resolve(
          storage: storage,
          ownerId: 'user-b',
          fingerprint: AiRequestFingerprint.soulMate(
            name: _name,
            birthDate: _birthIso,
          ),
          fresh: false,
        );
        expect(bLogicalId, isNot(_inflightSource),
            reason: 'user-b never reuses user-a\'s sourceRequestId');
      },
    );
  });
}
