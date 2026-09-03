/// Premium screen flow — free, active, tap does not fake-grant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/providers/premium_entitlement_verifier_provider.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

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
      PremiumVerifyResult.active('test_active');
}

class _ConfiguredStorePort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => isConfigured;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(
    WidgetTester tester,
    LocalStorage storage, {
    PremiumPurchasePort? purchasePort,
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        purchasePort: purchasePort,
        overrides: overrides,
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('free user sees unavailable copy, not fake prices',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await pumpScreen(tester, storage);

    expect(tester.takeException(), isNull);
    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.ctaHint), findsOneWidget);
    expect(find.text(PremiumCopy.ctaExplore), findsOneWidget);
    expect(find.byType(OraclyGoldButton), findsNothing);
    expect(find.text(PremiumCopy.ctaRestore), findsNothing);
    expect(find.text('Planı Seç'), findsNothing);
    expect(find.text('Aylık'), findsNothing);
    expect(find.text('Yıllık'), findsNothing);
    expect(find.textContaining('₺'), findsNothing);

    final notice = find.text(PremiumCopy.ctaUnavailable);
    await tester.scrollUntilVisible(notice, 200);
    await tester.pump();
    await tester.tap(notice, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text(PremiumCopy.ctaActive), findsNothing);
    expect(storage.getBool('or_premium_active') ?? false, isFalse);
  });

  testWidgets('stale local flag stays locked without successful verify',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'or_premium_active': true,
      'or_premium_authoritative': true,
      'or_premium_plan': PremiumPlanKind.yearly.index,
      'or_premium_platform': 'android',
      'or_premium_product_id': 'app.oracly.premium.yearly',
      'or_premium_purchase_token': 'valid-token',
    });
    final storage = await LocalStorage.open();
    await pumpScreen(tester, storage, purchasePort: _ConfiguredStorePort());
    expect(find.text(PremiumCopy.ctaActive), findsNothing);
    expect(find.text(PremiumCopy.ctaUnavailable), findsNothing);
  });

  testWidgets('premium user sees active status without purchase CTA',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'or_premium_active': true,
      'or_premium_authoritative': true,
      'or_premium_plan': PremiumPlanKind.yearly.index,
      'or_premium_platform': 'android',
      'or_premium_product_id': 'app.oracly.premium.yearly',
      'or_premium_purchase_token': 'valid-token',
    });
    final storage = await LocalStorage.open();
    await pumpScreen(
      tester,
      storage,
      purchasePort: _ConfiguredStorePort(),
      overrides: [
        premiumEntitlementVerifierProvider.overrideWithValue(_ActiveVerifier()),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text(PremiumCopy.ctaActive), findsOneWidget);
    expect(find.byType(OraclyGoldButton), findsNothing);
    expect(find.text('Planı Seç'), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.text('AKTİF'), findsOneWidget);
  });
}
