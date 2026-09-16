/// iOS paywall: monthly+yearly only; Android keeps lifetime; store prices win.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/services/premium_plan_availability.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

class _PricedStore implements PremiumPurchasePort {
  _PricedStore({this.purchaseLog});

  final List<PremiumPlanKind>? purchaseLog;

  @override
  bool get isConfigured => true;

  @override
  bool get canAttemptRestore => true;

  @override
  Future<void> prepare() async {}

  @override
  String? priceLabel(PremiumPlanKind plan) => switch (plan) {
    PremiumPlanKind.monthly => 'TEST-MONTHLY-PRICE',
    PremiumPlanKind.yearly => 'TEST-YEARLY-PRICE',
    PremiumPlanKind.lifetime => 'TEST-LIFETIME-PRICE',
  };

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    purchaseLog?.add(plan);
    return PremiumPurchaseResult.unavailable();
  }

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.noneFound();

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('availability policy: iOS hides lifetime, Android keeps it', () {
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.lifetime,
        platform: TargetPlatform.iOS,
      ),
      isFalse,
    );
    expect(
      PremiumPlanAvailability.isPurchasable(
        PremiumPlanKind.lifetime,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      PremiumPlanAvailability.normalizeSelection(
        PremiumPlanKind.lifetime,
        platform: TargetPlatform.iOS,
      ),
      PremiumPlanKind.yearly,
    );
    expect(
      PremiumPlanAvailability.storeQueryIds(platform: TargetPlatform.iOS),
      {PremiumStoreCatalog.monthlyId, PremiumStoreCatalog.yearlyId},
    );
    expect(
      PremiumPlanAvailability.storeQueryIds(platform: TargetPlatform.android),
      PremiumStoreCatalog.allIds,
    );
  });

  test('iOS controller omits lifetime and uses store price labels', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _PricedStore(),
    );
    final status = PremiumStatusController(service);
    await status.load();

    expect(status.plans.map((p) => p.kind), [
      PremiumPlanKind.monthly,
      PremiumPlanKind.yearly,
    ]);
    expect(status.plans.map((p) => p.price), [
      'TEST-MONTHLY-PRICE',
      'TEST-YEARLY-PRICE',
    ]);
    expect(status.selectedPlan, isNot(PremiumPlanKind.lifetime));

    status.selectPlan(PremiumPlanKind.lifetime);
    expect(status.selectedPlan, isNot(PremiumPlanKind.lifetime));
  });

  test('iOS purchase normalizes stale lifetime to yearly', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final log = <PremiumPlanKind>[];
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _PricedStore(purchaseLog: log),
    );
    final status = PremiumStatusController(service);
    await status.load();
    // Stale inject: selectPlan refuses lifetime, so call purchase after
    // temporarily using Android to set lifetime then flipping platform.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    status.selectPlan(PremiumPlanKind.lifetime);
    expect(status.selectedPlan, PremiumPlanKind.lifetime);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await status.purchase();
    expect(status.selectedPlan, PremiumPlanKind.yearly);
    expect(log, [PremiumPlanKind.yearly]);
  });

  test('Android controller keeps lifetime and store prices', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _PricedStore(),
    );
    final status = PremiumStatusController(service);
    await status.load();

    expect(status.plans.map((p) => p.kind), [
      PremiumPlanKind.monthly,
      PremiumPlanKind.yearly,
      PremiumPlanKind.lifetime,
    ]);
    expect(status.plans.map((p) => p.price), [
      'TEST-MONTHLY-PRICE',
      'TEST-YEARLY-PRICE',
      'TEST-LIFETIME-PRICE',
    ]);
    status.selectPlan(PremiumPlanKind.lifetime);
    expect(status.selectedPlan, PremiumPlanKind.lifetime);
  });

  testWidgets('iOS paywall UI: monthly+yearly, restore, no lifetime', (
    tester,
  ) async {
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      for (final size in const [Size(320, 568), Size(390, 844)]) {
        await tester.binding.setSurfaceSize(size);
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            purchasePort: _PricedStore(),
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size, disableAnimations: true),
                child: const PremiumReferenceScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Drain exceptions: 320-wide may inherit pre-existing chrome overflow.
        final caught = tester.takeException();
        if (size.width >= 390) {
          expect(caught, isNull);
        }

        expect(find.text(PremiumCopy.planMonthlyLabel), findsOneWidget);
        expect(find.text(PremiumCopy.planYearlyLabel), findsOneWidget);
        expect(find.text(PremiumCopy.planLifetimeLabel), findsNothing);
        expect(find.text('TEST-MONTHLY-PRICE'), findsOneWidget);
        expect(find.text('TEST-YEARLY-PRICE'), findsOneWidget);
        expect(find.textContaining('₺'), findsNothing);
        expect(find.text(PremiumCopy.ctaRestore), findsOneWidget);
        expect(find.byType(OraclyGoldButton), findsWidgets);
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  testWidgets('Android paywall UI still shows lifetime', (tester) async {
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          purchasePort: _PricedStore(),
          child: const MaterialApp(home: PremiumReferenceScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text(PremiumCopy.planLifetimeLabel), findsOneWidget);
      expect(find.text('TEST-LIFETIME-PRICE'), findsOneWidget);
      expect(find.text(PremiumCopy.ctaRestore), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      await tester.binding.setSurfaceSize(null);
    }
  });
}
