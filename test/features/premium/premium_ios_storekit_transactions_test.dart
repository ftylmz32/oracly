/// iOS StoreKit purchase / restore outcomes through the real controller path.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';

import 'support/ios_premium_controller_harness.dart';
import 'support/ios_storekit_fake.dart';

const _yearly = PremiumStoreCatalog.yearlyId;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('restore success -> verified entitlement, Premium active', () async {
    final iap = FakeStoreKit()
      ..restoreEmits = [storeTransaction(_yearly, PurchaseStatus.restored)];
    final (status, service) = await loadedIosPremium(iap);
    expect(status.isPremium, isFalse);
    final result = await status.restore();
    expect(result.outcome, PremiumPurchaseOutcome.restored);
    expect(status.isPremium, isTrue);
    expect(await service.isActive(), isTrue);
    expect(iap.completeCalls, 1);
  });

  test('purchase success -> verified entitlement, Premium active', () async {
    final iap = FakeStoreKit(products: [monthlyProduct, yearlyProduct])
      ..buyEmits = [storeTransaction(_yearly, PurchaseStatus.purchased)];
    final (status, service) = await loadedIosPremium(iap);
    expect(status.selectedPlan, PremiumPlanKind.yearly);
    final result = await status.purchase();
    expect(result.outcome, PremiumPurchaseOutcome.granted);
    expect(status.isPremium, isTrue);
    expect(status.activePlan, PremiumPlanKind.yearly);
    expect(await service.isActive(), isTrue);
    expect(iap.completeCalls, 1);
  });

  for (final (status, outcome) in [
    (PurchaseStatus.canceled, PremiumPurchaseOutcome.cancelled),
    (PurchaseStatus.error, PremiumPurchaseOutcome.failed),
  ]) {
    test('purchase ${status.name} -> no false Premium', () async {
      final iap = FakeStoreKit(products: [monthlyProduct, yearlyProduct])
        ..buyEmits = [storeTransaction(_yearly, status)];
      final (controller, service) = await loadedIosPremium(iap);
      final result = await controller.purchase();
      expect(result.outcome, outcome);
      expect(result.granted, isFalse);
      expect(controller.isPremium, isFalse);
      expect(await service.isActive(), isFalse);
      expect(iap.completeCalls, 0);
    });
  }

  test('purchase sheet fails to start -> no false Premium', () async {
    final iap = FakeStoreKit(products: [monthlyProduct, yearlyProduct])
      ..buyStarted = false;
    final (status, service) = await loadedIosPremium(iap);
    final result = await status.purchase();
    expect(result.granted, isFalse);
    expect(status.isPremium, isFalse);
    expect(await service.isActive(), isFalse);
  });
}
