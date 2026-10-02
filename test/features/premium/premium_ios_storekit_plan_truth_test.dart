/// iOS partial catalogues — only StoreKit-returned plans are offered,
/// selectable or purchasable; Retry Store is single-flight.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';

import 'support/ios_premium_controller_harness.dart';
import 'support/ios_storekit_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final (label, product, kind, missing) in [
    (
      'monthly only',
      monthlyProduct,
      PremiumPlanKind.monthly,
      PremiumPlanKind.yearly,
    ),
    (
      'yearly only',
      yearlyProduct,
      PremiumPlanKind.yearly,
      PremiumPlanKind.monthly,
    ),
  ]) {
    test('$label: offered alone, selected by default and purchasable', () async {
      final iap = FakeStoreKit(products: [product])
        ..buyEmits = [storeTransaction(product.id, PurchaseStatus.purchased)];
      final (status, _) = await loadedIosPremium(iap);
      expect(status.storeOffersPlans, isTrue);
      expect(status.plans.map((p) => p.kind), [kind]);
      expect(status.selectedPlan, kind);

      status.selectPlan(missing);
      expect(status.selectedPlan, kind, reason: 'missing plan refused');

      final result = await status.purchase();
      expect(result.outcome, PremiumPurchaseOutcome.granted);
      expect(iap.buyCalls, 1);
      expect(status.activePlan, kind);
    });
  }

  test('missing plan can never call purchase, even if stale-selected', () async {
    final iap = FakeStoreKit(products: [monthlyProduct])
      ..buyEmits = [
        storeTransaction(PremiumStoreCatalog.monthlyId, PurchaseStatus.purchased),
      ];
    final (status, _) = await loadedIosPremium(iap);
    // Stale selection injected under Android, where every plan is selectable.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    status.selectPlan(PremiumPlanKind.yearly);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(status.selectedPlan, PremiumPlanKind.yearly);

    await status.purchase();
    expect(status.selectedPlan, PremiumPlanKind.monthly);
    expect(iap.buyCalls, 1);
    expect(status.activePlan, PremiumPlanKind.monthly);
  });

  test('zero returned: nothing offered, purchase never reaches StoreKit',
      () async {
    final iap = FakeStoreKit();
    final (status, _) = await loadedIosPremium(iap);
    expect(status.storeOffersPlans, isFalse);
    expect(status.plans, isEmpty);
    for (final kind in PremiumPlanKind.values) {
      status.selectPlan(kind);
    }
    final result = await status.purchase();
    expect(result.outcome, PremiumPurchaseOutcome.unavailable);
    expect(iap.buyCalls, 0);
    expect(status.isPremium, isFalse);
  });

  test('lifetime never offered on iOS even when the store returns it',
      () async {
    final iap = FakeStoreKit(
      products: [monthlyProduct, yearlyProduct, lifetimeProduct],
      returnUnrequested: true,
    );
    final (status, _) = await loadedIosPremium(iap);
    expect(status.plans.map((p) => p.kind), [
      PremiumPlanKind.monthly,
      PremiumPlanKind.yearly,
    ]);
    status.selectPlan(PremiumPlanKind.lifetime);
    expect(status.selectedPlan, PremiumPlanKind.yearly);
  });

  test('retryStore is single-flight and publishes checking immediately',
      () async {
    final iap = FakeStoreKit();
    final (status, _) = await loadedIosPremium(iap);
    final before = iap.queriedIds.length;
    final gate = Completer<void>();
    iap
      ..products = [yearlyProduct]
      ..queryGate = gate;
    var notified = 0;
    status.addListener(() => notified++);

    final first = status.retryStore();
    expect(status.checkingStore, isTrue);
    expect(notified, greaterThan(0));
    final second = status.retryStore();
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await Future.wait([first, second]);

    expect(iap.queriedIds.length, before + 1);
    expect(status.checkingStore, isFalse);
    expect(status.plans.map((p) => p.kind), [PremiumPlanKind.yearly]);
  });
}
