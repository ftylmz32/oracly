/// WAVE 1.1 — a store-charged purchase (or restore) whose backend
/// `/billing/verify` fails TRANSIENTLY (network, 5xx, own-backend auth
/// hiccup) must not be closed as a definitive "unverified" outcome, must not
/// lose the durable purchase proof, and must not stay locked behind the
/// pre-purchase "inactive" freshness verdict. The same purchase must become
/// Premium once verification succeeds — never a second store charge.
///
/// Mirrors D's real store wiring: the store port persists the purchase proof
/// (StorePurchaseTerminalHandler -> savePurchaseCredentials) BEFORE the
/// granted result reaches PremiumGrantPolicy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

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

class _StorePort implements PremiumPurchasePort {
  _StorePort(this._premium);
  final MockPremiumRepository _premium;
  int purchases = 0;
  int restores = 0;

  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {}
  @override
  String? priceLabel(PremiumPlanKind plan) => null;

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    purchases++;
    await _premium.savePurchaseCredentials(_creds);
    return PremiumPurchaseResult.granted(plan, credentials: _creds);
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    restores++;
    await _premium.savePurchaseCredentials(_creds);
    return PremiumPurchaseResult.restored(
      PremiumPlanKind.monthly,
      credentials: _creds,
    );
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: PremiumStoreCatalog.monthlyId,
  purchaseToken: 'wave11-transient-token',
  transactionId: 'wave11-transient-txn',
);

class _Harness {
  _Harness(this.controller, this.verifier, this.port, this.premium, this.clock);
  final PremiumStatusController controller;
  final _ScriptedVerifier verifier;
  final _StorePort port;
  final MockPremiumRepository premium;
  final _Clock clock;
}

Future<_Harness> _freeUserOnPaywall(List<PremiumVerifyResult> results) async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final premium = MockPremiumRepository(
    storage,
    secureStorage: InMemorySecureStorage(),
  );
  final verifier = _ScriptedVerifier(results);
  final port = _StorePort(premium);
  final clock = _Clock(DateTime.utc(2026, 10, 4, 18));
  final service = PremiumService(
    premium,
    MockUserRepository(storage),
    port,
    verifier,
  )..forceReleaseMode = true;
  final controller = PremiumStatusController(service, now: clock.call);
  await controller.load();
  return _Harness(controller, verifier, port, premium, clock);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('precondition: paywall load is a definitive, fresh inactive verdict',
      () async {
    final h = await _freeUserOnPaywall([PremiumVerifyResult.active('ok')]);
    expect(h.controller.entitlement, PremiumEntitlementState.inactive);
    expect(h.controller.isFresh, isTrue);
    expect(h.verifier.calls, 0, reason: 'no proof yet, nothing to verify');
  });

  test(
    'charged purchase + transient verify error stays retryable (not a '
    'definitive unverified outcome) and keeps the purchase proof',
    () async {
      final h = await _freeUserOnPaywall([
        PremiumVerifyResult.error('network_or_parse'),
      ]);

      final result = await h.controller.purchase();

      expect(h.port.purchases, 1);
      expect(h.controller.isPremium, isFalse,
          reason: 'a transient error must never grant Premium');
      expect(await h.premium.isPremiumActive(), isFalse);
      expect(await h.premium.readPurchaseCredentials(), isNotNull,
          reason: 'the store-charged proof must survive the transient error');
      expect(result.outcome, isNot(PremiumPurchaseOutcome.unverified),
          reason: 'transient verify failure is not a store rejection');
      expect(h.controller.entitlement,
          isNot(PremiumEntitlementState.unverified));
    },
  );

  test(
    'charged purchase + transient verify error -> the pre-purchase inactive '
    'verdict is no longer fresh, so the next gate re-verifies the SAME proof '
    'and unlocks Premium without a second purchase',
    () async {
      // Purchase-time verify and any immediate follow-up both hit the outage;
      // the backend recovers before the next Premium gate / resume.
      final h = await _freeUserOnPaywall([
        PremiumVerifyResult.error('network_or_parse'),
        PremiumVerifyResult.error('network_or_parse'),
        PremiumVerifyResult.active('subscription_active'),
      ]);

      h.clock.advance(const Duration(seconds: 5));
      await h.controller.purchase();
      expect(h.controller.isPremium, isFalse);
      expect(h.verifier.calls, 2,
          reason: 'bounded: purchase verify + one reconcile, no retry loop');
      expect(await h.premium.readPurchaseCredentials(), isNotNull);
      expect(
        h.controller.isFresh,
        isFalse,
        reason: 'a store charge makes the pre-purchase inactive verdict stale',
      );

      // Well inside the 120s freshness window, past the transient throttle.
      h.clock.advance(PremiumStatusController.retryThrottle);
      await h.controller.ensureFresh();

      expect(h.controller.entitlement, PremiumEntitlementState.active);
      expect(h.controller.isPremium, isTrue);
      expect(h.port.purchases, 1, reason: 'no duplicate store purchase');
    },
  );

  test(
    'charged purchase + single transient blip -> immediate re-verification of '
    'the persisted proof unlocks Premium within the same purchase',
    () async {
      final h = await _freeUserOnPaywall([
        PremiumVerifyResult.error('http_503'),
        PremiumVerifyResult.active('subscription_active'),
      ]);

      await h.controller.purchase();

      expect(h.verifier.calls, 2);
      expect(h.controller.entitlement, PremiumEntitlementState.active);
      expect(h.port.purchases, 1);
    },
  );

  test(
    'restore + transient verify error stays retryable and keeps the proof',
    () async {
      final h = await _freeUserOnPaywall([
        PremiumVerifyResult.error('network_or_parse'),
      ]);

      final result = await h.controller.restore();

      expect(h.port.restores, 1);
      expect(h.controller.isPremium, isFalse);
      expect(await h.premium.readPurchaseCredentials(), isNotNull);
      expect(result.outcome, isNot(PremiumPurchaseOutcome.unverified));
      expect(h.controller.entitlement,
          isNot(PremiumEntitlementState.unverified));
    },
  );

  test('guard: a definitive store rejection is still unverified and never '
      'grants', () async {
    final h = await _freeUserOnPaywall([
      PremiumVerifyResult.unverified('product_mismatch'),
    ]);

    final result = await h.controller.purchase();

    expect(result.outcome, PremiumPurchaseOutcome.unverified);
    expect(h.controller.entitlement, PremiumEntitlementState.unverified);
    expect(h.controller.isPremium, isFalse);
  });

  test('guard: an active verification grants Premium on the first purchase',
      () async {
    final h = await _freeUserOnPaywall([
      PremiumVerifyResult.active('subscription_active'),
    ]);

    await h.controller.purchase();

    expect(h.controller.entitlement, PremiumEntitlementState.active);
    expect(h.port.purchases, 1);
  });
}
