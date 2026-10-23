/// Both Play and StoreKit paywalls must offer real store-returned products.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/services/premium_plan_availability.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PartialStore implements PremiumPurchasePort {
  _PartialStore(this.available, {this.configured = true});

  final Set<PremiumPlanKind> available;
  final bool configured;
  final purchases = <PremiumPlanKind>[];

  @override
  bool get isConfigured => configured;

  @override
  bool get canAttemptRestore => configured;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) =>
      available.contains(plan) ? 'STORE-${plan.name}' : null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    purchases.add(plan);
    return PremiumPurchaseResult.unavailable();
  }

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreUnavailable();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  final all = [
    for (final kind in PremiumPlanKind.values)
      PremiumPlanModel(
        kind: kind,
        label: kind.name,
        price: 'FALLBACK-PRICE',
        subtitle: '',
        isActive: false,
      ),
  ];

  test('Android never shows missing yearly/lifetime products', () {
    final offered = PremiumPlanAvailability.offeredPlans(
      all,
      platform: TargetPlatform.android,
      storeReturned: (kind) => kind == PremiumPlanKind.monthly,
    );
    expect(offered.map((p) => p.kind), [PremiumPlanKind.monthly]);
    expect(
      PremiumPlanAvailability.isOffered(
        PremiumPlanKind.yearly,
        offered,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
    expect(
      PremiumPlanAvailability.preferredSelection(
        PremiumPlanKind.yearly,
        offered,
        platform: TargetPlatform.android,
      ),
      PremiumPlanKind.monthly,
    );
  });

  test('iOS still never offers lifetime even when store returns it', () {
    final offered = PremiumPlanAvailability.offeredPlans(
      all,
      platform: TargetPlatform.iOS,
      storeReturned: (_) => true,
    );
    expect(offered.map((p) => p.kind), [
      PremiumPlanKind.monthly,
      PremiumPlanKind.yearly,
    ]);
  });

  test('no store-returned products means no plans or phantom CTA', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      final offered = PremiumPlanAvailability.offeredPlans(
        all,
        platform: platform,
        storeReturned: (_) => false,
      );
      expect(offered, isEmpty);
      for (final kind in PremiumPlanKind.values) {
        expect(
          PremiumPlanAvailability.isOffered(
            kind,
            offered,
            platform: platform,
          ),
          isFalse,
        );
      }
    }
  });

  test('Android controller only selects the single purchasable plan', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final port = _PartialStore({PremiumPlanKind.monthly});
    final status = PremiumStatusController(PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      port,
    ));
    addTearDown(status.dispose);
    await status.load();

    expect(status.storeOffersPlans, isTrue);
    expect(status.plans.map((p) => p.kind), [PremiumPlanKind.monthly]);
    expect(status.plans.single.price, 'STORE-monthly');
    expect(status.selectedPlan, PremiumPlanKind.monthly);

    status.selectPlan(PremiumPlanKind.yearly);
    status.selectPlan(PremiumPlanKind.lifetime);
    expect(status.selectedPlan, PremiumPlanKind.monthly);

    await status.purchase();
    expect(port.purchases, [PremiumPlanKind.monthly]);
  });

  test('configured port with missing catalog does not show a plan', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final port = _PartialStore({});
    final status = PremiumStatusController(PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      port,
    ));
    addTearDown(status.dispose);
    await status.load();

    expect(status.storeOffersPlans, isFalse);
    expect(status.plans, isEmpty);
    await status.purchase();
    expect(port.purchases, isEmpty);
  });
}
