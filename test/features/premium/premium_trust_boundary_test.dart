/// Premium entitlement trust boundary — local flags never grant authority alone.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/config/app_environment.dart';
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
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/premium_credential_keys.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Verifier implements PremiumEntitlementVerifier {
  _Verifier(this._result);
  final PremiumVerifyResult _result;
  @override
  bool get isRemoteVerifierConfigured => true;
  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => _result;
}

class _GrantPort implements PremiumPurchasePort {
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
      PremiumPurchaseResult.granted(
        plan,
        credentials: const PremiumPurchaseCredentials(
          platform: 'android',
          productId: 'app.oracly.premium.yearly',
          purchaseToken: 'token',
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

Future<MockPremiumRepository> _repo(Map<String, Object> seed) async {
  SharedPreferences.setMockInitialValues(seed);
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final secure = InMemorySecureStorage();
  final premium = MockPremiumRepository(storage, secureStorage: secure);
  await premium.warmCredentialCache();
  return premium;
}

PremiumEntitlementReconciler _reconciler(
  MockPremiumRepository premium,
  PremiumEntitlementVerifier verifier,
) =>
    PremiumEntitlementReconciler(
      premium: premium,
      purchaseConfigured: true,
      canAttemptRestore: true,
      verifier: verifier,
      forceReleaseMode: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local active alone cannot authorize Premium', () async {
    final premium = await _repo({'or_premium_active': true});
    final snap = await _reconciler(
      premium,
      const LocalCacheEntitlementVerifier(),
    ).reconcile();
    expect(snap.entitlement.allowsPremiumFeatures, isFalse);
  });

  test('tampered authoritative flag without verify does not grant Premium', () async {
    final premium = await _repo({
      'or_premium_active': true,
      'or_premium_authoritative': true,
    });
    final snap = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.unverified('stub')),
    ).reconcile();
    expect(snap.entitlement, PremiumEntitlementState.unverified);
    expect(await premium.isPremiumActive(), isFalse);
    expect(premium.wasAuthoritativelyVerified, isFalse);
  });

  test('missing credentials fail closed after authoritative cache', () async {
    final premium = await _repo({
      'or_premium_active': true,
      'or_premium_authoritative': true,
    });
    final snap = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.active('ok')),
    ).reconcile();
    expect(snap.entitlement, PremiumEntitlementState.unverified);
    expect(premium.readPurchaseCredentials(), isNull);
  });

  test('verifier error and unverified do not preserve Premium', () async {
    final seed = {
      'or_premium_active': true,
      'or_premium_authoritative': true,
      'or_premium_plan': PremiumPlanKind.lifetime.index,
      'or_premium_platform': 'android',
      'or_premium_product_id': 'app.oracly.premium.lifetime',
      'or_premium_purchase_token': 'lifetime-token',
    };
    for (final result in [
      PremiumVerifyResult.error('network'),
      PremiumVerifyResult.unverified('invalid'),
    ]) {
      final premium = await _repo(seed);
      final snap = await _reconciler(premium, _Verifier(result)).reconcile();
      expect(snap.entitlement.allowsPremiumFeatures, isFalse, reason: result.reason);
      expect(await premium.isPremiumActive(), isFalse);
    }
  });

  test('authenticated active verification grants Premium on restart', () async {
    final premium = await _repo({
      'or_premium_active': true,
      'or_premium_authoritative': true,
      'or_premium_plan': PremiumPlanKind.yearly.index,
      'or_premium_platform': 'android',
      'or_premium_product_id': 'app.oracly.premium.yearly',
      'or_premium_purchase_token': 'valid-token',
    });
    final snap = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.active('subscription_active')),
    ).reconcile();
    expect(snap.entitlement, PremiumEntitlementState.active);
    expect(await premium.isPremiumActive(), isTrue);
    expect(premium.wasAuthoritativelyVerified, isTrue);
  });

  test('inactive and expired verification demote Premium', () async {
    for (final result in [
      PremiumVerifyResult.inactive('revoked'),
      PremiumVerifyResult.expired('expired'),
    ]) {
      final premium = await _repo({
        'or_premium_active': true,
        'or_premium_authoritative': true,
        'or_premium_plan': PremiumPlanKind.monthly.index,
        'or_premium_platform': 'ios',
        'or_premium_product_id': 'app.oracly.premium.monthly',
        'or_premium_purchase_token': 'ios-token',
      });
      final snap = await _reconciler(premium, _Verifier(result)).reconcile();
      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(await premium.isPremiumActive(), isFalse);
    }
  });

  test('lifetime still requires authoritative verification on restart', () async {
    final premium = await _repo({
      'or_premium_active': true,
      'or_premium_authoritative': true,
      'or_premium_plan': PremiumPlanKind.lifetime.index,
      'or_premium_platform': 'android',
      'or_premium_product_id': 'app.oracly.premium.lifetime',
      'or_premium_purchase_token': 'lifetime-token',
    });
    final snap = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.unverified('not_verified')),
    ).reconcile();
    expect(snap.entitlement.allowsPremiumFeatures, isFalse);
  });

  test('legitimate purchase and restore still grant with active verifier', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      _GrantPort(),
      _Verifier(PremiumVerifyResult.active('ok')),
    )..forceReleaseMode = true;

    final purchase = await service.purchase(PremiumPlanKind.yearly);
    expect(purchase.granted, isTrue);
    expect(await service.isActive(), isTrue);
    expect(service.wasAuthoritativelyVerified, isTrue);

    final restore = await service.restore();
    expect(restore.granted, isTrue);
  });

  test('release build cannot use PremiumDevOverride', () {
    expect(
      PremiumDevOverride.allowsOverride(
        debugBuild: false,
        environment: AppEnvironment.development,
        flagEnabled: true,
      ),
      isFalse,
    );
  });

  test('null transactionId removes stale stored transaction evidence', () async {
    SharedPreferences.setMockInitialValues({
      MockPremiumRepository.transactionIdKey: 'stale-txn',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final secure = InMemorySecureStorage();
    final premium = MockPremiumRepository(storage, secureStorage: secure);
    await premium.warmCredentialCache();
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'new-token',
      ),
    );
    expect(storage.getString(MockPremiumRepository.transactionIdKey), isNull);
    expect(await secure.read(PremiumCredentialKeys.transactionId), isNull);
    expect(
      premium.readPurchaseCredentials()?.purchaseToken,
      'new-token',
    );
  });
}
