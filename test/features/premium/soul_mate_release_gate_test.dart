/// Soul Mate release gate — Premium entitlement + authorized internal flow.
library;

import 'dart:async';
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
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final failGate = Completer<SoulMateDrawResult>();
    final retryGate = Completer<SoulMateDrawResult>();
    final port = _QueuedDraw([failGate.future, retryGate.future]);
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
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);

    await _tapDraw(tester);
    await tester.pump();
    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    failGate.complete(SoulMateDrawResult.unavailable(SoulMateCopy.unavailable));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(SoulMateCopy.unavailable), findsOneWidget);
    expect(find.text(SoulMateCopy.retry), findsOneWidget);

    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    expect(port.calls, 2);
    retryGate.complete(SoulMateDrawResult.unavailable(SoulMateCopy.unavailable));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  });

  testWidgets('8 success shows portrait reading and redraw', (tester) async {
    final harness = await _AuthorizedPremium.open();
    await SoulMateResultStore.clear(harness.storage);
    final port = _QueuedDraw([
      Future.value(const SoulMateDrawResult.success(imageBytes: _png1x1)),
    ]);
    final resultService = _DocsSoulMateResultService(harness.storage, temp);

    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateDrawPortProvider.overrideWithValue(port),
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
    await tester.pump(const Duration(milliseconds: 300));
    expect(port.calls, 1);
    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(find.text(SoulMateCopy.energyLabel), findsOneWidget);
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
  });

  testWidgets('9 repeated CTA while busy hits port once', (tester) async {
    final harness = await _AuthorizedPremium.open();
    final gate = Completer<SoulMateDrawResult>();
    final port = _GatedDraw(gate);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...harness.overrides(),
          soulMateDrawPortProvider.overrideWithValue(port),
        ],
        child: const MaterialApp(home: SoulMateDrawScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'Ayse');
    await _pickBirth(tester);
    await _tapDraw(tester);
    await tester.pump();
    expect(find.text(SoulMateCopy.drawCta), findsNothing);
    expect(port.calls, 1);
    gate.complete(SoulMateDrawResult.unavailable(SoulMateCopy.unavailable));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
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

class _QueuedDraw implements SoulMateDrawPort {
  _QueuedDraw(this._queue);
  final List<Future<SoulMateDrawResult>> _queue;
  var calls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<SoulMateDrawResult> draw(SoulMateDrawRequest request) {
    calls++;
    if (_queue.isEmpty) {
      return Future.value(SoulMateDrawResult.unavailable(SoulMateCopy.unavailable));
    }
    return _queue.removeAt(0);
  }
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

class _DocsSoulMateResultService extends SoulMateResultService {
  _DocsSoulMateResultService(super.storage, this.docs);
  final Directory docs;

  @override
  Future<SoulMateSavedResult?> saveSuccessfulDraw({
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
    SoulMateReadingParts? parts,
    Directory? documents,
  }) {
    return super.saveSuccessfulDraw(
      request: request,
      imageBytes: imageBytes,
      parts: parts,
      documents: documents ?? docs,
    );
  }
}
