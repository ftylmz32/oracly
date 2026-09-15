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
) => PremiumEntitlementReconciler(
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

  test(
    'tampered authoritative flag without verify does not grant Premium',
    () async {
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
    },
  );

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
    expect(await premium.readPurchaseCredentials(), isNull);
  });

  final lifetimeSeed = {
    'or_premium_active': true,
    'or_premium_authoritative': true,
    'or_premium_plan': PremiumPlanKind.lifetime.index,
    'or_premium_platform': 'android',
    'or_premium_product_id': 'app.oracly.premium.lifetime',
    'or_premium_purchase_token': 'lifetime-token',
  };

  test('verifier definitive unverified clears a previously-cached Premium '
      'grant', () async {
    final premium = await _repo(lifetimeSeed);
    final snap = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.unverified('invalid')),
    ).reconcile();
    expect(snap.entitlement.allowsPremiumFeatures, isFalse);
    expect(await premium.isPremiumActive(), isFalse);
  });

  // A. A transient verify error must never demote an already-verified,
  // previously-active Premium subscriber — the store never said the
  // purchase was invalid, verification just couldn't complete right now.
  test('A: verified active Premium + transient verify error -> Premium '
      'remains locally active', () async {
    final premium = await _repo(lifetimeSeed);
    final snap = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.error('network')),
    ).reconcile();
    expect(snap.entitlement, PremiumEntitlementState.active);
    expect(snap.entitlement.allowsPremiumFeatures, isTrue);
    expect(await premium.isPremiumActive(), isTrue);
  });

  // B. A user who was never authoritatively verified must never be granted
  // Premium off the back of a transient error — `reconcile()` never even
  // reaches the verifier for such a user (no local-active + verified
  // evidence to refresh), so this proves the fail-closed default holds.
  test(
    'B: never-verified user + transient error -> Premium is NOT granted',
    () async {
      final premium = await _repo({
        'or_premium_active': true,
        // Deliberately no 'or_premium_authoritative' — never verified.
      });
      final snap = await _reconciler(
        premium,
        _Verifier(PremiumVerifyResult.error('network')),
      ).reconcile();
      expect(snap.entitlement.allowsPremiumFeatures, isFalse);
      expect(await premium.isPremiumActive(), isFalse);
    },
  );

  // C. A definitive denial (expired/inactive) must still clear access —
  // already covered by 'inactive and expired verification demote Premium'
  // below; this restates it explicitly against the lifetime seed used by
  // the transient-error tests above, for direct side-by-side contrast.
  test('C: definitive inactive/expired still clears a previously-active '
      'Premium grant', () async {
    for (final result in [
      PremiumVerifyResult.inactive('revoked'),
      PremiumVerifyResult.expired('expired'),
    ]) {
      final premium = await _repo(lifetimeSeed);
      final snap = await _reconciler(premium, _Verifier(result)).reconcile();
      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(await premium.isPremiumActive(), isFalse, reason: result.reason);
    }
  });

  // D. After a transient error preserved the grant, a later successful
  // verify must reconcile normally (stay active, re-confirm authoritative).
  test('D: a later successful verify reconciles normally after a prior '
      'transient error', () async {
    final premium = await _repo(lifetimeSeed);
    final afterError = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.error('network')),
    ).reconcile();
    expect(afterError.entitlement, PremiumEntitlementState.active);
    expect(await premium.isPremiumActive(), isTrue);

    final afterRecovery = await _reconciler(
      premium,
      _Verifier(PremiumVerifyResult.active('subscription_active')),
    ).reconcile();
    expect(afterRecovery.entitlement, PremiumEntitlementState.active);
    expect(await premium.isPremiumActive(), isTrue);
    expect(premium.wasAuthoritativelyVerified, isTrue);
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

  test(
    'lifetime still requires authoritative verification on restart',
    () async {
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
    },
  );

  test(
    'legitimate purchase and restore still grant with active verifier',
    () async {
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
    },
  );

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

  test(
    'null transactionId removes stale stored transaction evidence',
    () async {
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
      expect((await premium.readPurchaseCredentials())?.purchaseToken, 'new-token');
    },
  );
}
