/// Soul Mate release gate — Premium entitlement + authorized internal flow.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_persistence.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_preview.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_result_view.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_entry_hero.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_providers.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_saved_provider.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/premium/services/soul_mate_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_context.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

const _png1x1 = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;

  setUp(() async {
    PremiumDevOverride.resetDebug();
    temp = await Directory.systemTemp.createTemp('soulmate_gate_');
  });

  tearDown(() async {
    PremiumDevOverride.resetDebug();
    try {
      if (await temp.exists()) await temp.delete(recursive: true);
    } catch (_) {}
  });

  testWidgets('1 non-Premium shows honest gate preview, not draw form',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    final element = tester.element(find.byType(SoulMateDrawScreen));
    await ProviderScope.containerOf(element).read(premiumStatusProvider).load();
    await tester.pump();

    expect(find.byType(SoulMateDrawPreview), findsOneWidget);
    expect(find.text(SoulMateCopy.drawCta), findsNothing);
    expect(find.text(PremiumCopy.unlockTitle), findsWidgets);
  });

  testWidgets(
      '2 authorized Premium opens real Soul Mate form without debug bypass',
      (tester) async {
    final harness = await _AuthorizedPremium.open();
    expect(PremiumDevOverride.isActive, isFalse);
    expect(harness.status.isPremium, isTrue);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text(SoulMateCopy.drawCta), findsOneWidget);
    expect(find.byType(SoulMateDrawPreview), findsNothing);
    expect(find.byType(SoulMateEntryHero), findsOneWidget);
    expect(find.byType(OraclyAssetImage), findsWidgets);
  });

  testWidgets('3 missing required data blocks draw', (tester) async {
    final harness = await _AuthorizedPremium.open();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _tapDraw(tester);
    expect(find.text(SoulMateCopy.birthRequired), findsWidgets);
  });

  testWidgets('4-7 loading failure then retry reaches port again',
      (tester) async {
    // SMD1 — no local port to queue: the durable worker's own failure
    // (surfaced via `/fail`) and the durable retry (a fresh operation)
    // replace the old queued-port simulation.
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final resultService = _InMemorySoulMateResultService(harness.storage);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateResultServiceProvider.overrideWithValue(resultService),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);

    await _tapDraw(tester);
    await tester.pump();
    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    expect(harness.backend.operationCount, 1);

    final firstOp = await harness.backend.send(
      'GET',
      '/v1/reading-flow/active?readingType=soulmate',
      null,
    );
    final firstId =
        ((firstOp!.json!['data'] as Map)['operation'] as Map)['operationId']
            as String;
    await harness.backend.send(
      'POST',
      '/v1/reading-operations/$firstId/fail',
      const {},
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text(SoulMateCopy.failureTemporary), findsOneWidget);
    expect(find.text(SoulMateCopy.retry), findsOneWidget);

    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    expect(harness.backend.operationCount, 2);
  });

  testWidgets('8 success shows portrait reading and redraw', (tester) async {
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final resultService = _InMemorySoulMateResultService(harness.storage);

    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateResultServiceProvider.overrideWithValue(resultService),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 1400),
            disableAnimations: true,
          ),
          child: const MaterialApp(home: SoulMateDrawScreen()),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    expect(harness.backend.operationCount, 1);

    final active = await harness.backend.send(
      'GET',
      '/v1/reading-flow/active?readingType=soulmate',
      null,
    );
    final operationId =
        ((active!.json!['data'] as Map)['operation'] as Map)['operationId']
            as String;
    harness.backend.setSoulmatePortrait(
      operationId,
      imageBase64: base64Encode(_png1x1),
    );
    harness.backend.completeServerSide(
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
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    // A durable `ready` operation always carries its full interpretation
    // already (never a partial/"interpreting…" phase) — see SMD1 §6.
    expect(find.text(SoulMateCopy.energyLabel), findsOneWidget);
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
  });

  testWidgets('9 repeated CTA while busy creates exactly one operation',
      (tester) async {
    final harness = await _AuthorizedPremium.open();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    // Busy immediately hides the draw button (SoulMateDrawWaiting takes
    // its place) — the same `_drawLock`/`_busy` guard that blocks a
    // same-frame double submit also means there is nothing left to tap.
    expect(find.text(SoulMateCopy.drawCta), findsNothing);
    expect(harness.backend.operationCount, 1);
  });

  testWidgets('10 navigate away while loading still persists success',
      (tester) async {
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final gate = Completer<SoulMateDrawResult>();
    final port = _GatedDraw(gate);
    final resultService = _DocsSoulMateResultService(harness.storage, temp);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateDrawPortProvider.overrideWithValue(port),
          soulMateResultServiceProvider.overrideWithValue(resultService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SoulMateDrawScreen(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    expect(find.text(SoulMateCopy.drawing), findsWidgets);

    // Dispose the route while the draw is still pending.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(find.byType(SoulMateDrawScreen), findsNothing);

    gate.complete(const SoulMateDrawResult.success(imageBytes: _png1x1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  test('10b persistWithService saves without a live WidgetRef', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await SoulMateResultStore.clear(storage);
    final service = _DocsSoulMateResultService(storage, temp);
    final id = await SoulMateDrawPersistence.persistWithService(
      service: service,
      request: SoulMateDrawRequest(
        name: 'Ayse',
        birthDate: DateTime(1994, 3, 12),
      ),
      imageBytes: _png1x1,
    );
    expect(id, isNotNull);
    expect(await service.hasSavedResult(), isTrue);
  });

  test('11 reopen loads saved portrait bytes from store', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await SoulMateResultStore.clear(storage);
    final service = _DocsSoulMateResultService(storage, temp);
    await service.saveSuccessfulDraw(
      request: SoulMateDrawRequest(
        name: 'Ayse',
        birthDate: DateTime(1994, 3, 12),
      ),
      imageBytes: _png1x1,
      documents: temp,
    );
    final loaded = await service.latestWithPortrait();
    expect(loaded, isNotNull);
    expect(loaded!.bytes, isNotEmpty);
    expect(loaded.meta.name, 'Ayse');
  });

  testWidgets('12 small viewport + text scale has no overflow', (tester) async {
    final harness = await _AuthorizedPremium.open();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: const MaterialApp(home: SoulMateDrawScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(SoulMateCopy.screenTitle), findsOneWidget);
  });

  test('13-15 interpretation localizes TR EN RU from real inputs', () {
    final request = SoulMateDrawRequest(
      name: 'Ayse',
      birthDate: DateTime(1994, 3, 12),
      intention: 'calm bond',
    );
    OraclyL10n.bind('tr');
    expect(SoulMateInterpretation.forRequest(request), contains('ilkbahar'));
    OraclyL10n.bind('en');
    expect(SoulMateInterpretation.forRequest(request), contains('spring'));
    OraclyL10n.bind('ru');
    expect(SoulMateInterpretation.forRequest(request), contains('весеннем'));
    OraclyL10n.bind('tr');
  });

  testWidgets(
      '16 retry after terminal failure starts a fresh operation but keeps '
      'one journal entry', (tester) async {
    // SMD1 — the durable path's own internal retry-after-failed logic
    // (SoulMateReadingOrchestrator.drawDurable) generates a fresh
    // sourceRequestId automatically once a submission's own operation is
    // found `failed` — no local port queue is involved anymore.
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final resultService = _InMemorySoulMateResultService(harness.storage);

    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateResultServiceProvider.overrideWithValue(resultService),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    expect(harness.backend.operationCount, 1);

    final firstOp = await harness.backend.send(
      'GET',
      '/v1/reading-flow/active?readingType=soulmate',
      null,
    );
    final firstId =
        ((firstOp!.json!['data'] as Map)['operation'] as Map)['operationId']
            as String;
    await harness.backend.send(
      'POST',
      '/v1/reading-operations/$firstId/fail',
      const {},
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text(SoulMateCopy.failureTemporary), findsOneWidget);

    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    // A genuinely new operation, never the same stale-failed record.
    expect(harness.backend.operationCount, 2);

    final secondOp = await harness.backend.send(
      'GET',
      '/v1/reading-flow/active?readingType=soulmate',
      null,
    );
    final secondId =
        ((secondOp!.json!['data'] as Map)['operation'] as Map)['operationId']
            as String;
    expect(secondId, isNot(firstId));
    harness.backend.setSoulmatePortrait(
      secondId,
      imageBase64: base64Encode(_png1x1),
    );
    harness.backend.completeServerSide(
      secondId,
      resultId: 'soulmate_$secondId',
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
    await tester.pump();

    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    // Soulmate's local Journal is a single "latest" slot — two DIFFERENT
    // operationIds across the failed-then-retried attempt still converge
    // on exactly one saved entry.
    final saved = await resultService.latestWithPortrait();
    expect(saved, isNotNull);
    expect(saved!.meta.id, secondId);
  });

  testWidgets(
      '17 a fresh screen (simulated app relaunch) detects a still-processing '
      'operation without any AI call', (tester) async {
    // SMD1 — a new submission is server-authoritative: the client never
    // calls a local AI port at all, so this is now proven by showing that
    // recovery finds the SAME durable operation (never a second one) via
    // the backend alone, exactly like a real relaunch would.
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    expect(harness.backend.operationCount, 1);

    // A brand-new screen instance sharing only the durable backend +
    // storage — exactly what a fresh app process looks like. The runner
    // provider is rebuilt fresh (no in-memory Future survives), so this
    // can only be detected via the durable ReadingOperation, not a local
    // in-flight Future.
    await tester.pumpWidget(
      ProviderScope(
        overrides: harness.overrides(),
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    expect(
      harness.backend.operationCount,
      1,
      reason: 'recovery must never create a second operation',
    );
  });

  testWidgets(
      '18 portrait survives an interpretation failure; manual retry is '
      'bounded at 2 total attempts', (tester) async {
    // SMD1 — a NEW durable draw can no longer land in "portrait ok,
    // interpretation failed" at all (the durable worker only reaches
    // `ready` once both stages succeed — see §5/§6). The still-reachable
    // equivalent is a previously-saved LOCAL Journal entry with a
    // non-authoritative interpretation (e.g. from before this update);
    // opening the screen restores it, and the bounded manual-repair
    // button (still local, still 2 attempts total) is unchanged.
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final resultService = _InMemorySoulMateResultService(harness.storage);
    await resultService.saveSuccessfulDraw(
      request: SoulMateDrawRequest(name: 'Ayse', birthDate: DateTime(1994, 3, 12)),
      imageBytes: _png1x1,
      recordId: 'legacy-partial-01',
      parts: const SoulMateReadingParts(
        energy: '',
        attraction: '',
        dynamics: '',
        feeling: '',
        yourSide: '',
        authoritative: false,
      ),
    );
    final interpretation = _CountingFailInterpretation();

    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateResultServiceProvider.overrideWithValue(resultService),
          soulMateInterpretationPortProvider.overrideWithValue(interpretation),
        ],
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 1400), disableAnimations: true),
          child: const MaterialApp(home: SoulMateDrawScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Portrait shows even though interpretation never succeeded.
    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(find.text(SoulMateCopy.interpretationFailed), findsOneWidget);
    expect(interpretation.calls, 0);

    await tester.scrollUntilVisible(find.text(SoulMateCopy.retry), 120);
    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(interpretation.calls, 1);

    await tester.scrollUntilVisible(find.text(SoulMateCopy.retry), 120);
    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(interpretation.calls, 2);

    // Bound spent — a further tap must not call the port again.
    await tester.scrollUntilVisible(find.text(SoulMateCopy.retry), 120);
    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(interpretation.calls, 2, reason: 'bounded — no third attempt');
  });
}

class _ActiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async =>
      PremiumVerifyResult.active('test');
}

class _AuthorizedPremium {
  _AuthorizedPremium({
    required this.storage,
    required this.users,
    required this.service,
    required this.status,
  });

  final LocalStorage storage;
  final MockUserRepository users;
  final PremiumService service;
  final PremiumStatusController status;
  final FakeReadingOperationBackend backend = FakeReadingOperationBackend();

  static Future<_AuthorizedPremium> open() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final secure = InMemorySecureStorage();
    final premium = MockPremiumRepository(storage, secureStorage: secure);
    final users = MockUserRepository(storage);
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'token',
      ),
    );
    final service = PremiumService(
      premium,
      users,
      const _ConfiguredPort(),
      _ActiveVerifier(),
    );
    final status = PremiumStatusController(service);
    await status.load();
    expect(status.isPremium, isTrue);
    return _AuthorizedPremium(
      storage: storage,
      users: users,
      service: service,
      status: status,
    );
  }

  List<Override> overrides() => [
        localStorageProvider.overrideWithValue(storage),
        secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
        premiumServiceProvider.overrideWithValue(service),
        premiumStatusProvider.overrideWith((ref) => status),
        userRepositoryProvider.overrideWithValue(users),
        readingFeatureRunnerProvider.overrideWithValue(
          fakeImmediateReadingFeatureRunner(backend: backend),
        ),
        readingOperationInputGatewayProvider.overrideWithValue(
          fakeReadingOperationInputGateway(backend: backend),
        ),
      ];
}

class _ConfiguredPort implements PremiumPurchasePort {
  const _ConfiguredPort();

  @override
  bool get isConfigured => true;

  @override
  bool get canAttemptRestore => true;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.unavailable();

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreUnavailable();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
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

Future<void> _pickBirth(WidgetTester tester) async {
  await tester.tap(find.text(SoulMateCopy.birthHint));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  final ok = find.text('OK');
  final tamam = find.text('Tamam');
  await tester.tap(ok.evaluate().isNotEmpty ? ok : tamam);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

class _GatedDraw implements SoulMateDrawPort {
  _GatedDraw(this.gate);
  final Completer<SoulMateDrawResult> gate;
  var calls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) {
    calls++;
    return gate.future;
  }
}

/// Pure in-memory result service — avoids real file writes (which have
/// shown intermittent hangs specifically inside `testWidgets`'s fake-async
/// zone in this environment) while preserving the exact same owner/hash
/// guard and upsert semantics as the real `SoulMateResultService`.
class _InMemorySoulMateResultService extends SoulMateResultService {
  _InMemorySoulMateResultService(super.storage);

  SoulMateSavedResult? _latest;

  @override
  Future<SoulMateSavedResult?> latestMeta() async => _latest;

  @override
  Future<({SoulMateSavedResult meta, List<int> bytes})?> latestWithPortrait() async {
    final meta = _latest;
    if (meta == null) return null;
    return (meta: meta, bytes: const [1, 2, 3]);
  }

  @override
  Future<bool> hasSavedResult() async => _latest != null;

  @override
  Future<SoulMateSavedResult?> saveSuccessfulDraw({
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
    SoulMateReadingParts? parts,
    Directory? documents,
    String? recordId,
    String? expectedOwnerId,
    SoulMateIdentity? identity,
  }) async {
    if (imageBytes.isEmpty) return null;
    final id = (recordId ?? '').isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : recordId!;
    final previous = _latest;
    final keepPriorText = parts?.authoritative != true &&
        previous != null &&
        previous.id == id &&
        previous.hasAuthoritativeInterpretation;
    final resolved = keepPriorText
        ? previous.parts
        : (parts ??
            const SoulMateReadingParts(
              energy: '',
              attraction: '',
              dynamics: '',
              feeling: '',
              yourSide: '',
            ));
    final saved = SoulMateSavedResult(
      id: id,
      createdAt: DateTime.now(),
      name: request.name.trim(),
      birthDate: request.birthDate,
      gender: request.gender,
      intention: request.intention,
      portraitPath: 'memory://$id',
      parts: resolved,
      identity: identity ?? (previous?.id == id ? previous?.identity : null),
    );
    _latest = saved;
    return saved;
  }

  @override
  Future<void> clear() async {
    _latest = null;
  }
}

class _CountingFailInterpretation implements SoulMateInterpretationPort {
  var calls = 0;

  @override
  Future<SoulMateInterpretationOutcome> interpret(
    SoulMateInterpretationContext context,
  ) async {
    calls++;
    return const SoulMateInterpretationOutcome.failed();
  }
}

class _DocsSoulMateResultService extends SoulMateResultService {
  _DocsSoulMateResultService(super.storage, this.docs);
  final Directory docs;

  @override
  Future<SoulMateSavedResult?> saveSuccessfulDraw({
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
    SoulMateReadingParts? parts,
    Directory? documents,
    String? recordId,
    String? expectedOwnerId,
    SoulMateIdentity? identity,
  }) {
    return super.saveSuccessfulDraw(
      request: request,
      imageBytes: imageBytes,
      parts: parts,
      documents: documents ?? docs,
      recordId: recordId,
      expectedOwnerId: expectedOwnerId,
      identity: identity,
    );
  }
}
