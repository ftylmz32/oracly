/// Entitlement verifier honesty — local cache is never production authority.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_entitlement_reconciler.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/local_cache_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _GrantPort implements PremiumPurchasePort {
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
      PremiumPurchaseResult.granted(
        plan,
        credentials: const PremiumPurchaseCredentials(
          platform: 'android',
          productId: 'app.oracly.premium.yearly',
          purchaseToken: 'token',
          transactionId: 'txn',
        ),
      );

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restored(
        PremiumPlanKind.yearly,
        credentials: const PremiumPurchaseCredentials(
          platform: 'android',
          productId: 'app.oracly.premium.yearly',
          purchaseToken: 'token',
        ),
      );

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocalCacheEntitlementVerifier never returns active', () async {
    const verifier = LocalCacheEntitlementVerifier();
    expect(verifier.isRemoteVerifierConfigured, isFalse);
    final result = await verifier.verify(
      platform: 'android',
      productId: 'app.oracly.premium.yearly',
      purchaseToken: 'local-only',
    );
    expect(result.status, PremiumVerifyStatus.unverified);
    expect(result.isActive, isFalse);
    expect(result.reason, isNotNull);
  });

  test('unverified local flag is demoted on release reconcile path', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final premium = MockPremiumRepository(storage);
    await premium.activatePlan(PremiumPlanKind.yearly);
    expect(premium.wasAuthoritativelyVerified, isFalse);
    final snap = await PremiumEntitlementReconciler(
      premium: premium,
      purchaseConfigured: true,
      verifier: const LocalCacheEntitlementVerifier(),
      forceReleaseMode: true,
    ).reconcile();
    expect(snap.entitlement, PremiumEntitlementState.unverified);
    expect(snap.entitlement.allowsPremiumFeatures, isFalse);
    expect(await premium.isPremiumActive(), isFalse);
  });

  test('release path does not grant on unverified local cache', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _GrantPort(),
      const LocalCacheEntitlementVerifier(),
    )..forceReleaseMode = true;
    final result = await service.purchase(PremiumPlanKind.yearly);
    expect(result.granted, isFalse);
    expect(result.outcome, PremiumPurchaseOutcome.unverified);
    expect(await service.isActive(), isFalse);
    expect(service.wasAuthoritativelyVerified, isFalse);
  });

  test('active remote verifier grants authoritatively', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _GrantPort(),
      _ActiveVerifier(),
    );
    final result = await service.purchase(PremiumPlanKind.yearly);
    expect(result.granted, isTrue);
    expect(await service.isActive(), isTrue);
    expect(service.wasAuthoritativelyVerified, isTrue);
  });

  test('dev override grant stays non-authoritative', () async {
    PremiumDevOverride.debugEnvironment = AppEnvironment.development;
    PremiumDevOverride.debugFlag = true;
    addTearDown(PremiumDevOverride.resetDebug);
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _GrantPort(),
      const LocalCacheEntitlementVerifier(),
    );
    final result = await service.purchase(PremiumPlanKind.yearly);
    // Debug tests allow optional QA grant; never mark authoritative.
    expect(result.granted, isTrue);
    expect(await service.isActive(), isTrue);
    expect(service.wasAuthoritativelyVerified, isFalse);
  });
}
