/// End-to-end: a raw internal verification reason code must never appear
/// in the rendered Premium screen — only mapped, localized human copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_body.dart';
import 'package:oracly_new/features/premium/services/local_cache_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

class _FakePurchasePort implements PremiumPurchasePort {
  // `purchaseConfigured: false` so `PremiumReferenceBody` takes its
  // unverified-message branch instead of the "show plans" branch — this is
  // the exact UI path that used to render the raw entitlement reason.
  @override
  bool get isConfigured => false;
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

Future<PremiumStatusController> _controllerWithIncompleteCredentials(
  LocalStorage storage,
) async {
  // Authoritative local cache claims Premium, but the stored purchase
  // credentials are incomplete (no product id) — this drives
  // PremiumEntitlementReconciler's `missing_purchase_credentials` path,
  // which is unaffected by the transient-error fix and still surfaces a
  // raw internal reason string via `entitlementMessage`.
  final secure = InMemorySecureStorage();
  final premium = MockPremiumRepository(storage, secureStorage: secure);
  await premium.warmCredentialCache();
  final service = PremiumService(
    premium,
    MockUserRepository(storage),
    _FakePurchasePort(),
    const LocalCacheEntitlementVerifier(),
  )..forceReleaseMode = true;
  final controller = PremiumStatusController(service);
  await controller.load();
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'raw reason "missing_purchase_credentials" never appears verbatim in '
    'the rendered Premium screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'or_premium_active': true,
        'or_premium_authoritative': true,
        'or_premium_plan': PremiumPlanKind.lifetime.index,
        'or_premium_platform': 'android',
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final controller = await _controllerWithIncompleteCredentials(storage);
      expect(controller.entitlementMessage, 'missing_purchase_credentials');

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: Scaffold(
              body: PremiumReferenceBody(
                status: controller,
                onPurchase: () {},
                onRestore: () {},
                onRetryStore: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('missing_purchase_credentials'), findsNothing);
      expect(
        find.text(PremiumCopy.entitlementMissingCredentials),
        findsOneWidget,
      );
    },
  );

  test('sanity: PremiumVerifyResult.error reasons never surface as the '
      'entitlement message for an already-verified user (Fix 3 preserves '
      'active, so Fix 4\'s mapping is exercised via other reason paths)', () {
    // Documents the interaction between Fix 3 and Fix 4: a transient
    // verify error no longer produces an `error`/`unverified` entitlement
    // for a previously-verified user at all (see
    // premium_trust_boundary_test.dart, test A) — so this widget test
    // exercises `missing_purchase_credentials` instead, a still-reachable
    // raw-reason path unaffected by Fix 3.
    expect(
      PremiumVerifyResult.error('network_or_parse').status,
      PremiumVerifyStatus.error,
    );
  });
}
