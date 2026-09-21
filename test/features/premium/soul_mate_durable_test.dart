/// SMD1 — server-authoritative Soulmate durable pipeline (client side).
/// Focused coverage for §16's client-relevant scenarios: durable
/// submission/progress, controller-recreation/restart recovery, Journal
/// idempotency, and stale-legacy detection without an infinite spinner or
/// an automatic provider call.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_waiting.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

void _unlockDevPremium() {
  PremiumDevOverride.debugEnvironment = AppEnvironment.development;
  PremiumDevOverride.debugFlag = true;
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// Real dart:io file writes (the local Journal) need a genuine event-loop
/// turn to settle — the fake test clock alone does not advance them. Same
/// `runAsync` + interleaved-delay pattern as coffee_v2_guided_capture_test's
/// `drain()`, for the same reason (real file I/O inside a durable-poll
/// timer callback).
Future<void> _settleRealIo(WidgetTester tester, {int iterations = 15}) {
  return tester.runAsync(() async {
    for (var i = 0; i < iterations; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await tester.pump();
    }
  });
}

/// A tiny 1x1 PNG, matching the fixture already used by
/// soul_mate_draw_test.dart's `_SuccessDraw`.
const _pngBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x00,
  0x03,
  0x00,
  0x01,
  0x00,
  0x05,
  0xFE,
  0xD4,
  0xEF,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
final _pngBase64 = base64Encode(_pngBytes);

Future<LocalStorage> _premiumStorage() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  _unlockDevPremium();
  await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.yearly);
  return storage;
}

Widget _screen(
  LocalStorage storage,
  FakeReadingOperationBackend backend, {
  String? operationId,
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      readingFeatureRunnerProvider.overrideWithValue(
        fakeImmediateReadingFeatureRunner(backend: backend),
      ),
      readingOperationInputGatewayProvider.overrideWithValue(
        fakeReadingOperationInputGateway(backend: backend),
      ),
    ],
    child: MaterialApp(home: SoulMateDrawScreen(operationId: operationId)),
  );
}

Future<void> _loadPremium(WidgetTester tester) async {
  final element = tester.element(find.byType(SoulMateDrawScreen));
  await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
  await tester.pump();
}

Future<void> _pickDefaultBirth(WidgetTester tester) async {
  await tester.tap(find.text(SoulMateCopy.birthHint));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final ok = find.text('OK');
  final tamam = find.text('Tamam');
  await tester.tap(ok.evaluate().isNotEmpty ? ok : tamam);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _tapDraw(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final cta = find.text(SoulMateCopy.drawCta);
  await tester.ensureVisible(cta);
  await tester.pump();
  await tester.tap(cta);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(PremiumDevOverride.resetDebug);

  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('soulmate_durable_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
  });
  tearDown(() async {
    // A just-completed real write can still hold a Windows file handle for
    // a brief moment after the test body returns; a bounded retry avoids a
    // flaky teardown failure unrelated to what the test actually verifies.
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
    'durable submission shows progress then renders the server-completed result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final backend = FakeReadingOperationBackend();

      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);

      await tester.enterText(find.byType(TextField).first, 'Ada');
      await _pickDefaultBirth(tester);
      await _tapDraw(tester);
      await tester.pump();

      // Submission is fire-and-forget: the operation is created (durable)
      // and the client is left observing, never claiming/executing itself.
      expect(backend.operationCount, 1);
      expect(find.text(SoulMateCopy.drawing), findsWidgets);

      // Simulate the durable worker finishing server-side while the
      // client is mid-poll.
      final activeId = backend.operationCount == 1
          ? (await _activeOperationId(tester, backend))
          : null;
      expect(activeId, isNotNull);
      backend.setSoulmatePortrait(activeId!, imageBase64: _pngBase64);
      backend.completeServerSide(
        activeId,
        resultId: 'soulmate_$activeId',
        result: const {
          'personality': 'p',
          'dynamic': 'd',
          'attraction': 'a',
          'challenge': 'c',
          'meeting': 'm',
          'feeling': 'f',
        },
      );

      // The screen's own poll timer (3s) discovers completion.
      await tester.pump(const Duration(seconds: 4));
      await _settleRealIo(tester);
      await tester.pump();

      expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
      expect(find.text(SoulMateCopy.drawing), findsNothing);
      final saved = await SoulMateResultStore.readMeta(storage);
      expect(saved?.id, activeId);
      expect(saved?.hasAuthoritativeInterpretation, isTrue);
    },
  );

  testWidgets(
    'controller recreation (rebuild) resumes the same durable operation, never a second one',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);

      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);

      await tester.enterText(find.byType(TextField).first, 'Ada');
      await _pickDefaultBirth(tester);
      await _tapDraw(tester);
      await tester.pump();
      expect(backend.operationCount, 1);

      // Destroy and recreate the screen (a fresh controller/State, same
      // storage + same fake backend) — simulates a navigation rebuild.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(backend.operationCount, 1);
      expect(find.text(SoulMateCopy.drawing), findsWidgets);
    },
  );

  testWidgets(
    'active durable operation survives leaving and reopening, then ready renders without retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);

      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);
      await tester.enterText(find.byType(TextField).first, 'Ada');
      await _pickDefaultBirth(tester);
      await _tapDraw(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SoulMateDrawWaiting), findsOneWidget);
      expect(find.text(SoulMateCopy.retry), findsNothing);
      expect(backend.operationCount, 1);

      // Existing back/navigation behavior disposes only the presentation;
      // the authoritative operation remains active and recoverable.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(backend.operationCount, 1);
      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(backend.operationCount, 1);
      expect(find.byType(SoulMateDrawWaiting), findsOneWidget);
      expect(find.text(SoulMateCopy.retry), findsNothing);

      final activeId = await _activeOperationId(tester, backend);
      expect(activeId, isNotNull);
      backend.setSoulmatePortrait(activeId!, imageBase64: _pngBase64);
      backend.completeServerSide(
        activeId,
        resultId: 'soulmate_$activeId',
        result: const {
          'personality': 'p',
          'dynamic': 'd',
          'attraction': 'a',
          'challenge': 'c',
          'meeting': 'm',
          'feeling': 'f',
        },
      );
      await tester.pump(const Duration(seconds: 4));
      await _settleRealIo(tester);
      await tester.pump();

      expect(find.text(SoulMateCopy.drawingSlowTitle), findsNothing);
      expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
      expect(backend.operationCount, 1);
    },
  );

  testWidgets(
    'cold recovery after process restart renders the already-ready result exactly once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final backend = FakeReadingOperationBackend();

      // The operation completed entirely server-side while no client ever
      // observed it (app was killed before submit() even returned, then
      // relaunched) — simulate by driving the fake backend directly,
      // never through this test's own screen instance.
      final created = await backend.send('POST', '/v1/reading-operations', {
        'readingType': 'soulmate',
        'sourceRequestId': 'cold-recovery-01aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'language': 'tr',
        'executionMode': 'durable',
      });
      final operationId =
          (created!.json!['data'] as Map)['operationId'] as String;
      await backend.send('POST', '/v1/reading-operations/$operationId/input', {
        'name': 'Ada',
        'birthIso': '1995-03-02',
      });
      backend.setSoulmatePortrait(operationId, imageBase64: _pngBase64);
      backend.completeServerSide(
        operationId,
        resultId: 'soulmate_$operationId',
        result: const {
          'personality': 'p',
          'dynamic': 'd',
          'attraction': 'a',
          'challenge': 'c',
          'meeting': 'm',
          'feeling': 'f',
        },
      );

      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);
      await _settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
      final firstSave = await SoulMateResultStore.readMeta(storage);
      expect(firstSave?.id, operationId);

      // Reopen again (a second cold recovery of the SAME completed
      // operation) — must upsert the same Journal row, not add another.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);
      await _settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 100));

      final secondSave = await SoulMateResultStore.readMeta(storage);
      expect(secondSave?.id, operationId);
    },
  );

  testWidgets(
    'exact completion target opens that Soul Mate operation even when another Soul Mate is active',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final backend = FakeReadingOperationBackend();

      final targetCreated = await backend.send(
        'POST',
        '/v1/reading-operations',
        {
          'readingType': 'soulmate',
          'sourceRequestId': 'push-target-soulmate-01aaaaaaaaaaaaaaaaaaaaaaaa',
          'language': 'tr',
          'executionMode': 'durable',
        },
      );
      final targetId =
          (targetCreated!.json!['data'] as Map)['operationId'] as String;
      await backend.send('POST', '/v1/reading-operations/$targetId/input', {
        'name': 'Target Ada',
        'birthIso': '1995-03-02',
      });
      backend.setSoulmatePortrait(targetId, imageBase64: _pngBase64);
      backend.completeServerSide(
        targetId,
        resultId: 'soulmate_$targetId',
        result: const {
          'personality': 'target-p',
          'dynamic': 'target-d',
          'attraction': 'target-a',
          'challenge': 'target-c',
          'meeting': 'target-m',
          'feeling': 'target-f',
        },
      );

      final otherCreated = await backend.send(
        'POST',
        '/v1/reading-operations',
        {
          'readingType': 'soulmate',
          'sourceRequestId': 'other-active-soulmate-01aaaaaaaaaaaaaaaaaaaaaaa',
          'language': 'tr',
          'executionMode': 'durable',
        },
      );
      final otherId =
          (otherCreated!.json!['data'] as Map)['operationId'] as String;
      await backend.send('POST', '/v1/reading-operations/$otherId/input', {
        'name': 'Other Ada',
        'birthIso': '1996-04-03',
      });

      expect(otherId, isNot(targetId));
      expect(await _activeOperationId(tester, backend), otherId);

      await tester.pumpWidget(
        _screen(storage, backend, operationId: targetId),
      );
      await tester.pump();
      await _loadPremium(tester);
      await _settleRealIo(tester);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
      expect(find.text(SoulMateCopy.drawing), findsNothing);
      final saved = await SoulMateResultStore.readMeta(storage);
      expect(saved?.id, targetId);
      expect(backend.operationCount, 2);
    },
  );

  testWidgets(
    'a stale legacy (pre-SMD1) processing operation never spins forever and retry starts a NEW durable operation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = await _premiumStorage();
      final backend = FakeReadingOperationBackend();

      // A legacy client-driven Soulmate operation stuck in `processing` —
      // no `executionMode`, exactly like every pre-SMD1 (1.0.0+26091304)
      // submission. No durable worker will ever touch this.
      final created = await backend.send('POST', '/v1/reading-operations', {
        'readingType': 'soulmate',
        'sourceRequestId': 'legacy-stuck-01aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'language': 'tr',
      });
      final legacyId = (created!.json!['data'] as Map)['operationId'] as String;
      // The legacy flow already saves structured input too (BATCH 5G,
      // pre-SMD1) — seeded here so the controlled retry can refill the
      // form without asking the user to retype it.
      await backend.send('POST', '/v1/reading-operations/$legacyId/input', {
        'name': 'Ada',
        'birthIso': '1995-03-02',
      });
      await backend.send(
        'POST',
        '/v1/reading-operations/$legacyId/claim',
        const {},
      );

      await tester.pumpWidget(_screen(storage, backend));
      await tester.pump();
      await _loadPremium(tester);
      await tester.pump(const Duration(milliseconds: 100));

      // Not busy, not an infinite spinner — a controlled, tappable retry
      // state instead.
      expect(find.byType(SoulMateDrawWaiting), findsNothing);
      expect(find.text(SoulMateCopy.retry), findsOneWidget);
      expect(backend.operationCount, 1);

      await tester.tap(find.text(SoulMateCopy.retry));
      await tester.pump();

      // The retry starts a genuinely NEW durable operation; the stale
      // legacy record is left untouched (never mutated, never re-called).
      expect(backend.operationCount, 2);
      final legacyStillProcessing = await backend.send(
        'GET',
        '/v1/reading-operations/$legacyId/result',
        null,
      );
      expect(legacyStillProcessing?.statusCode, 404);
    },
  );
}

/// Reads back the operationId of the currently-active Soulmate operation
/// via the fake backend's own `/v1/reading-flow/active` route — the same
/// endpoint the screen itself polls.
Future<String?> _activeOperationId(
  WidgetTester tester,
  FakeReadingOperationBackend backend,
) async {
  final wire = await backend.send(
    'GET',
    '/v1/reading-flow/active?readingType=soulmate',
    null,
  );
  final data = wire?.json?['data'];
  final operation = data is Map ? data['operation'] : null;
  return operation is Map ? operation['operationId'] as String? : null;
}
