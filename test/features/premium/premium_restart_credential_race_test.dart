/// LIVE INCIDENT REGRESSION — a real Google Play test purchase went active,
/// then a normal close/reopen of the app silently reverted to free.
///
/// Root cause: `PremiumStatusController.load()` (wired to fire the moment
/// `premiumStatusProvider` is first read) races `main.dart`'s
/// `MockPremiumRepository.warmCredentialCache()` on a fresh app process.
/// `PremiumEntitlementReconciler._refreshVerified()` needs the secure-stored
/// purchase credentials to re-verify with the server; before this fix,
/// `readPurchaseCredentials()` was synchronous and, when asked before the
/// cache had been warmed, silently treated "not loaded yet" as "does not
/// exist" — wiping a real, previously-authoritatively-verified grant
/// (`clearLocalPremiumAccess()`) without ever calling `/v1/billing/verify`
/// again. Confirmed against real Cloud Logging: the purchase's two
/// `billing_verify` calls both happened at purchase time; the restart that
/// reverted to free made zero further calls to the backend at all.
///
/// These tests simulate a real process restart correctly: two separate
/// `MockPremiumRepository` instances sharing the SAME underlying
/// `LocalStorage`/`SecureStorage` (which is what actually survives a real
/// app close/reopen), never calling `warmCredentialCache()` on the second
/// instance unless a test is specifically about that call happening (this
/// is the exact race window that caused the live failure).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_entitlement_reconciler.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScriptedVerifier implements PremiumEntitlementVerifier {
  _ScriptedVerifier(this._results);
  final List<PremiumVerifyResult> _results;
  int calls = 0;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final result = _results[calls.clamp(0, _results.length - 1)];
    calls++;
    return result;
  }
}

class _GrantPort implements PremiumPurchasePort {
  _GrantPort(this._credentials);
  final PremiumPurchaseCredentials _credentials;

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
      PremiumPurchaseResult.granted(plan, credentials: _credentials);
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restored(
        _planKindFor(_credentials.productId),
        credentials: _credentials,
      );
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

// Local, test-only mapping -- avoids importing the store catalog just for a
// restore-path fake that never runs in these tests.
PremiumPlanKind _planKindFor(String productId) => productId.contains('monthly')
    ? PremiumPlanKind.monthly
    : productId.contains('yearly')
        ? PremiumPlanKind.yearly
        : PremiumPlanKind.lifetime;

const _realPurchase = PremiumPurchaseCredentials(
  platform: 'android',
  productId: 'app.oracly.premium.monthly',
  purchaseToken: 'real-play-purchase-token',
  transactionId: 'GPA.3341-0665-4226-25654',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'purchase -> restart (unwarmed cache) -> Premium remains active',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      // Session 1: the real purchase, exactly as it happened on-device.
      final firstSession = MockPremiumRepository(storage, secureStorage: secure);
      final verifier = _ScriptedVerifier([
        PremiumVerifyResult.active('subscription_active'),
      ]);
      final service = PremiumService(
        firstSession,
        MockUserRepository(storage),
        _GrantPort(_realPurchase),
        verifier,
      )..forceReleaseMode = true;
      final purchase = await service.purchase(PremiumPlanKind.monthly);
      expect(purchase.granted, isTrue);
      expect(firstSession.wasAuthoritativelyVerified, isTrue);

      // "App fully closed and reopened": a BRAND NEW repository instance
      // over the SAME durable storage/secure storage, exactly like a real
      // process restart -- and, deliberately, `warmCredentialCache()` is
      // NEVER called on it, reproducing the exact race that caused the
      // live failure (reconcile firing before bootstrap's warm-up finishes).
      final restarted = MockPremiumRepository(storage, secureStorage: secure);
      final reconciler = PremiumEntitlementReconciler(
        premium: restarted,
        purchaseConfigured: true,
        verifier: _ScriptedVerifier([
          PremiumVerifyResult.active('subscription_active'),
        ]),
        forceReleaseMode: true,
      );
      final snap = await reconciler.reconcile();

      expect(
        snap.entitlement,
        PremiumEntitlementState.active,
        reason: 'a real, previously-verified purchase must survive a normal '
            'app restart without requiring Restore Purchases',
      );
      expect(await restarted.isPremiumActive(), isTrue);
      expect(restarted.wasAuthoritativelyVerified, isTrue);
    },
  );

  test(
    'restart with slow bootstrap: reconcile called before warmCredentialCache '
    'still recovers real credentials and re-verifies, never demotes on the '
    'unwarmed read itself',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();
      await secure.write(
        'or_premium_purchase_token_secure',
        'unused-probe',
      );

      final firstSession = MockPremiumRepository(storage, secureStorage: secure);
      await firstSession.activatePlan(PremiumPlanKind.monthly, authoritative: true);
      await firstSession.savePurchaseCredentials(_realPurchase);

      // Simulate "bootstrap is slow": construct the restarted repository and
      // call reconcile on it immediately, with no warm-up call at all and no
      // artificial delay inserted anywhere -- the fix must not depend on
      // timing, only on correctly awaiting the real secure-storage read.
      final restarted = MockPremiumRepository(storage, secureStorage: secure);
      final creds = await restarted.readPurchaseCredentials();
      expect(
        creds?.purchaseToken,
        _realPurchase.purchaseToken,
        reason: 'credentials must be recoverable even when asked before '
            'warmCredentialCache() has ever run on this instance',
      );

      final reconciler = PremiumEntitlementReconciler(
        premium: restarted,
        purchaseConfigured: true,
        verifier: _ScriptedVerifier([
          PremiumVerifyResult.active('subscription_active'),
        ]),
        forceReleaseMode: true,
      );
      final snap = await reconciler.reconcile();
      expect(snap.entitlement, PremiumEntitlementState.active);
    },
  );

  test(
    'restart with a transient network failure does not erase valid stored '
    'purchase credentials -- a later successful reconcile still works',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      final firstSession = MockPremiumRepository(storage, secureStorage: secure);
      await firstSession.activatePlan(PremiumPlanKind.monthly, authoritative: true);
      await firstSession.savePurchaseCredentials(_realPurchase);

      // Restart #1: the network is briefly down.
      final restarted1 = MockPremiumRepository(storage, secureStorage: secure);
      final flaky = PremiumEntitlementReconciler(
        premium: restarted1,
        purchaseConfigured: true,
        verifier: _ScriptedVerifier([PremiumVerifyResult.error('network')]),
        forceReleaseMode: true,
      );
      final afterNetworkError = await flaky.reconcile();
      expect(
        afterNetworkError.entitlement,
        PremiumEntitlementState.active,
        reason: 'a transient verify error must never demote an already '
            'proven grant',
      );
      // The credentials themselves must still be intact on disk -- a
      // transient failure must not have wiped anything.
      final restarted2 = MockPremiumRepository(storage, secureStorage: secure);
      final survivingCreds = await restarted2.readPurchaseCredentials();
      expect(survivingCreds?.purchaseToken, _realPurchase.purchaseToken);

      // Restart #2 (or the network recovering): normal reconcile succeeds.
      final recovered = PremiumEntitlementReconciler(
        premium: restarted2,
        purchaseConfigured: true,
        verifier: _ScriptedVerifier([
          PremiumVerifyResult.active('subscription_active'),
        ]),
        forceReleaseMode: true,
      );
      final finalSnap = await recovered.reconcile();
      expect(finalSnap.entitlement, PremiumEntitlementState.active);
      expect(restarted2.wasAuthoritativelyVerified, isTrue);
    },
  );

  test(
    'stored purchase credentials survive normal app process death without '
    'ever calling warmCredentialCache again',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();

      final firstSession = MockPremiumRepository(storage, secureStorage: secure);
      await firstSession.savePurchaseCredentials(_realPurchase);

      // Process death: a fresh Dart object graph, same durable storage.
      final afterDeath = MockPremiumRepository(storage, secureStorage: secure);
      final creds = await afterDeath.readPurchaseCredentials();
      expect(creds, isNotNull);
      expect(creds!.purchaseToken, _realPurchase.purchaseToken);
      expect(creds.productId, _realPurchase.productId);
      expect(creds.transactionId, _realPurchase.transactionId);
    },
  );

  test(
    'restore is the correct (and only) path when credentials are genuinely '
    'missing -- fresh install / no local secure storage at all',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      // A genuinely fresh install: nothing was ever written here, so
      // `wasAuthoritativelyVerified`/`isPremiumActive` are both false and
      // reconcile never even reaches the verifier -- this must stay
      // `inactive`, not `active`, proving the fix does not overreach.
      final freshInstall = MockPremiumRepository(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      final reconciler = PremiumEntitlementReconciler(
        premium: freshInstall,
        purchaseConfigured: true,
        canAttemptRestore: true,
        verifier: _ScriptedVerifier([
          PremiumVerifyResult.active('subscription_active'),
        ]),
        forceReleaseMode: true,
      );
      final snap = await reconciler.reconcile();
      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(await freshInstall.readPurchaseCredentials(), isNull);

      // The only legitimate recovery here is an explicit Restore, which
      // goes through the store (not local cache) and re-runs the full
      // verify+grant path -- covered by premium_restore_resilience_test.dart.
      final status = PremiumStatusController(
        PremiumService(
          freshInstall,
          MockUserRepository(storage),
          _GrantPort(_realPurchase),
          _ScriptedVerifier([PremiumVerifyResult.active('ok')]),
        )..forceReleaseMode = true,
      );
      await status.load();
      expect(status.isPremium, isFalse);
      final restore = await status.restore();
      expect(restore.granted, isTrue);
      expect(status.isPremium, isTrue);
    },
  );
}
