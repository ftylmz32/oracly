/// P0 — Premium purchase UI must not fake a store transaction.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/domain/repositories/premium_repository.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck_selection/deck_selection_data.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
  });

  Future<void> pumpPremium(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('Premium screen has no fake purchase or restore CTA',
      (tester) async {
    await pumpPremium(tester);

    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.ctaHint), findsOneWidget);
    expect(find.text(PremiumCopy.ctaExplore), findsOneWidget);
    expect(find.byType(OraclyGoldButton), findsNothing);
    expect(find.text(PremiumCopy.ctaRestore), findsNothing);
    expect(find.text('Satın Al'), findsNothing);
    expect(find.text('Abone Ol'), findsNothing);
    expect(find.text("Premium'u Aç"), findsNothing);
    expect(find.text(PremiumCopy.ctaActive), findsNothing);
    expect(find.text('Planı Seç'), findsNothing);
    expect(find.text('Seçildi'), findsNothing);
    expect(find.text('₺149,99/ay'), findsNothing);
    expect(find.text('₺899,99/yıl'), findsNothing);
    expect(find.text('₺2.499,99'), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('tapping unavailable notice cannot activate Premium',
      (tester) async {
    await pumpPremium(tester);
    final notice = find.text(PremiumCopy.ctaUnavailable);
    await tester.scrollUntilVisible(notice, 200);
    await tester.pump();
    await tester.tap(notice, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(storage.getBool('or_premium_active') ?? false, isFalse);
    expect(find.text(PremiumCopy.ctaActive), findsNothing);
    expect(find.text(PremiumCopy.activatedMessage), findsNothing);
    expect(find.text(PremiumCopy.restoreSuccess), findsNothing);
  });

  testWidgets('live shell never calls MockPremiumRepository.activatePlan',
      (tester) async {
    final spy = _CountingPremiumRepository(MockPremiumRepository(storage));
    await tester.binding.setSurfaceSize(const Size(360, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          premiumRepositoryProvider.overrideWithValue(spy),
        ],
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Planı Seç'), findsNothing);
    expect(find.byType(OraclyGoldButton), findsNothing);
    final notice = find.text(PremiumCopy.ctaUnavailable);
    await tester.scrollUntilVisible(notice, 200);
    await tester.pump();
    await tester.tap(notice, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(spy.activatePlanCalls, 0);
    expect(storage.getBool('or_premium_active') ?? false, isFalse);
  });

  test('unavailable port never grants or restores', () async {
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      const UnavailablePremiumPurchase(),
    );
    final status = PremiumStatusController(service);
    await status.load();
    expect(status.purchaseConfigured, isFalse);
    expect(status.isPremium, isFalse);

    final purchase = await status.purchase();
    expect(purchase.granted, isFalse);
    expect(purchase.message, PremiumCopy.ctaUnavailable);
    expect(status.isPremium, isFalse);
    expect(await service.isActive(), isFalse);

    final restore = await status.restore();
    expect(restore.granted, isFalse);
    expect(restore.message, PremiumCopy.restoreUnavailable);
    expect(status.isPremium, isFalse);
    expect(await service.activePlan(), isNull);
  });

  test('premiumStatusProvider authority stays free without store grant', () async {
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
    );
    expect(service.purchaseConfigured, isFalse);
    expect(await service.isActive(), isFalse);
    expect((await MockUserRepository(storage).getProfile()).isPremium, isFalse);
  });

  test('free classic deck remains the only selectable deck', () {
    expect(TarotDeckCatalogue.decks, hasLength(1));
    expect(TarotDeckCatalogue.decks.first.requiresPremium, isFalse);
    expect(TarotDeckCatalogue.isSelectable('classic'), isTrue);
    expect(TarotDeckCatalogue.isSelectable('golden'), isFalse);
    expect(TarotDeckCatalogue.isUnbuilt('golden'), isTrue);
  });

  test('unavailable port has no store product IDs', () {
    expect(PremiumPlanKind.values, hasLength(3));
    const port = UnavailablePremiumPurchase();
    expect(port.isConfigured, isFalse);
  });
}

class _CountingPremiumRepository implements PremiumRepository {
  _CountingPremiumRepository(this._inner);

  final MockPremiumRepository _inner;
  int activatePlanCalls = 0;

  @override
  Future<bool> isPremiumActive() => _inner.isPremiumActive();

  @override
  bool get isActiveNow => _inner.isActiveNow;

  @override
  bool get wasAuthoritativelyVerified => _inner.wasAuthoritativelyVerified;

  @override
  Future<PremiumPlanKind?> activePlan() => _inner.activePlan();

  @override
  Future<void> activatePlan(
    PremiumPlanKind plan, {
    bool authoritative = false,
  }) async {
    activatePlanCalls++;
    await _inner.activatePlan(plan, authoritative: authoritative);
  }

  @override
  Future<void> clearLocalPremiumAccess() => _inner.clearLocalPremiumAccess();

  @override
  Future<void> savePurchaseCredentials(credentials) =>
      _inner.savePurchaseCredentials(credentials);

  @override
  PremiumPurchaseCredentials? readPurchaseCredentials() =>
      _inner.readPurchaseCredentials();

  @override
  Future<List<PremiumPlanModel>> getPlans() => _inner.getPlans();
}
