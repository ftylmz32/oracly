/// R3 — Premium entitlement synchronization: freshness, single-flight,
/// resume coalescing, and live-incident Soulmate stale-Premium regression.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
  void advance(Duration d) => value = value.add(d);
}

class _ScriptedVerifier implements PremiumEntitlementVerifier {
  _ScriptedVerifier([List<PremiumVerifyResult>? results])
      : _results = results ?? [];
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
    final result = _results.isEmpty
        ? PremiumVerifyResult.active('ok')
        : _results[calls.clamp(0, _results.length - 1)];
    calls++;
    return result;
  }
}

class _Port implements PremiumPurchasePort {
  _Port(this.credentials);
  final PremiumPurchaseCredentials credentials;
  int prepareCalls = 0;

  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {
    prepareCalls++;
  }

  @override
  String? priceLabel(PremiumPlanKind plan) => null;
  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.granted(plan, credentials: credentials);
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restored(
        PremiumPlanKind.monthly,
        credentials: credentials,
      );
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: 'app.oracly.premium.monthly',
  purchaseToken: 'r3-token',
  transactionId: 'r3-txn',
);

Future<({PremiumStatusController c, _ScriptedVerifier v, _Clock clock})>
    _activeController({
  List<PremiumVerifyResult>? verifyResults,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorage(prefs);
  final secure = InMemorySecureStorage();
  final premium = MockPremiumRepository(storage, secureStorage: secure);
  await premium.activatePlan(PremiumPlanKind.monthly, authoritative: true);
  await premium.savePurchaseCredentials(_creds);
  final verifier = _ScriptedVerifier(verifyResults);
  final clock = _Clock(DateTime.utc(2026, 9, 15, 12));
  final service = PremiumService(
    premium,
    MockUserRepository(storage),
    _Port(_creds),
    verifier,
  );
  final controller = PremiumStatusController(service, now: clock.call);
  await controller.load();
  return (c: controller, v: verifier, clock: clock);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Premium cache and credentials are invisible across an unisolated owner switch',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      final secure = InMemorySecureStorage();

      await storage.setString(UserLocalDataIsolation.ownerKey, 'uid-a');
      final seed = MockPremiumRepository(storage, secureStorage: secure);
      await seed.savePurchaseCredentials(_creds);
      await seed.activatePlan(PremiumPlanKind.monthly, authoritative: true);

      var liveUid = 'uid-b';
      final guarded = MockPremiumRepository(
        storage,
        secureStorage: secure,
        ownerAccessAllowed: () =>
            storage.getString(UserLocalDataIsolation.ownerKey) == liveUid,
      );

      expect(guarded.isActiveNow, isFalse);
      expect(guarded.wasAuthoritativelyVerified, isFalse);
      expect(await guarded.activePlan(), isNull);
      expect(await guarded.readPurchaseCredentials(), isNull);

      await expectLater(
        guarded.activatePlan(
          PremiumPlanKind.monthly,
          authoritative: true,
        ),
        throwsStateError,
      );

      await storage.setString(UserLocalDataIsolation.ownerKey, 'uid-b');
      expect(guarded.isActiveNow, isTrue);
      expect(guarded.wasAuthoritativelyVerified, isTrue);
      expect(
        (await guarded.readPurchaseCredentials())?.purchaseToken,
        _creds.purchaseToken,
      );

      liveUid = 'uid-c';
      expect(guarded.isActiveNow, isFalse);
    },
  );

  test('cold startup reconciles Premium', () async {
    final h = await _activeController();
    expect(h.c.loaded, isTrue);
    expect(h.c.isPremium, isTrue);
    expect(h.v.calls, greaterThanOrEqualTo(1));
  });

  test('fresh ensureFresh does not re-verify', () async {
    final h = await _activeController();
    final before = h.v.calls;
    await h.c.ensureFresh();
    expect(h.v.calls, before);
  });

  test('stale ensureFresh reconciles once', () async {
    final h = await _activeController();
    final before = h.v.calls;
    h.clock.advance(PremiumStatusController.freshnessWindow +
        const Duration(seconds: 1));
    await h.c.ensureFresh();
    expect(h.v.calls, before + 1);
  });

  test('rapid stale ensureFresh shares one in-flight reconcile', () async {
    final h = await _activeController(
      verifyResults: [
        PremiumVerifyResult.active('a'),
        PremiumVerifyResult.active('b'),
        PremiumVerifyResult.active('c'),
      ],
    );
    h.clock.advance(const Duration(minutes: 3));
    final before = h.v.calls;
    await Future.wait([
      h.c.ensureFresh(),
      h.c.ensureFresh(),
      h.c.ensureFresh(),
    ]);
    expect(h.v.calls, before + 1);
    expect(h.c.hasInFlightReconcile, isFalse);
  });

  test('definitive expiry demotes Premium', () async {
    final h = await _activeController(
      verifyResults: [
        PremiumVerifyResult.active('boot'),
        PremiumVerifyResult.expired('sandbox_expired'),
      ],
    );
    expect(h.c.isPremium, isTrue);
    h.clock.advance(const Duration(minutes: 3));
    await h.c.ensureFresh();
    expect(h.c.isPremium, isFalse);
    expect(h.c.entitlement, PremiumEntitlementState.inactive);
  });

  test('transient verify error keeps previously-active Premium', () async {
    final h = await _activeController(
      verifyResults: [
        PremiumVerifyResult.active('boot'),
        PremiumVerifyResult.error('network_or_parse'),
      ],
    );
    h.clock.advance(const Duration(minutes: 3));
    await h.c.ensureFresh();
    expect(h.c.isPremium, isTrue);
    expect(h.c.entitlement, PremiumEntitlementState.active);
    // R3.1 — transient must not mark entitlement fresh.
    expect(h.c.isFresh, isFalse);
  });

  test('forceReconcile bypasses freshness after denial signal', () async {
    final h = await _activeController(
      verifyResults: [
        PremiumVerifyResult.active('boot'),
        PremiumVerifyResult.expired('denied'),
      ],
    );
    final before = h.v.calls;
    // Still within freshness window — ensureFresh would no-op.
    await h.c.ensureFresh();
    expect(h.v.calls, before);
    await h.c.forceReconcile();
    expect(h.v.calls, before + 1);
    expect(h.c.isPremium, isFalse);
  });

  test('live incident: stale active + expiry blocks paid gate', () async {
    // INITIAL: UI/cache says Premium active; last verify is stale.
    final h = await _activeController(
      verifyResults: [
        PremiumVerifyResult.active('boot'),
        PremiumVerifyResult.expired('sandbox_naturally_expired'),
      ],
    );
    expect(h.c.isPremium, isTrue);
    h.clock.advance(const Duration(minutes: 3));

    // USER retries Soulmate → preflight ensureFresh.
    await h.c.ensureFresh();

    // EXPECTED: demoted; no client submission would proceed.
    expect(h.c.isPremium, isFalse);
    expect(h.c.entitlement, PremiumEntitlementState.inactive);
  });

  test('inactive then verified active updates correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final premium = MockPremiumRepository(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    final verifier = _ScriptedVerifier([PremiumVerifyResult.active('ok')]);
    final service = PremiumService(
      premium,
      MockUserRepository(storage),
      _Port(_creds),
      verifier,
    );
    final c = PremiumStatusController(service);
    await c.load();
    expect(c.isPremium, isFalse);

    await premium.activatePlan(PremiumPlanKind.monthly, authoritative: true);
    await premium.savePurchaseCredentials(_creds);
    await c.forceReconcile();
    expect(c.isPremium, isTrue);
  });
}
