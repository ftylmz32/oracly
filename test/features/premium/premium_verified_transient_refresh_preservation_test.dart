/// WAVE 1.3 — an ALREADY VERIFIED Premium subscriber must not be demoted when
/// the entitlement refresh cannot be performed right now because of our own
/// verification infrastructure (`auth_required`: own-backend 401 / token
/// refresh race; `provider_not_configured`: deployment has no store
/// credentials). Apple/Google were never consulted in either case.
/// A genuine definitive store verdict (expired / revoked) must still demote.
///
/// End-to-end through D's real HttpBillingEntitlementVerifier (MockClient
/// transport) and PremiumEntitlementReconciler / PremiumStatusController.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
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
import 'package:oracly_new/features/premium/services/http_billing_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: PremiumStoreCatalog.monthlyId,
  purchaseToken: 'wave13-verified-token',
  transactionId: 'wave13-verified-txn',
);

/// Backend stand-in; the reply can change between calls.
class _Backend {
  http.Response Function() reply = () => http.Response('', 401);
  int calls = 0;
  Future<void> Function()? onCall;

  HttpBillingEntitlementVerifier verifier() => HttpBillingEntitlementVerifier(
        verifyUrl: 'https://api.example.com/v1/billing/verify',
        client: MockClient((request) async {
          calls++;
          await onCall?.call();
          return reply();
        }),
      );

  static http.Response json(Map<String, Object?> body) =>
      http.Response(jsonEncode(body), 200);
}

http.Response _authRequired() => http.Response('', 401);
http.Response _providerNotConfigured() => _Backend.json(
      {'status': 'unverified', 'reason': 'provider_not_configured'},
    );
http.Response _expired() =>
    _Backend.json({'status': 'expired', 'reason': 'subscription_expired'});
http.Response _revoked() =>
    _Backend.json({'status': 'inactive', 'reason': 'revoked'});
http.Response _active() =>
    _Backend.json({'status': 'active', 'reason': 'subscription_active'});

class _NoopPort implements PremiumPurchasePort {
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
      PremiumPurchaseResult.cancelled();
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.noneFound();
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

late LocalStorage _storage;

Future<MockPremiumRepository> _verifiedSubscriber({String owner = 'user-a'}) async {
  SharedPreferences.setMockInitialValues({});
  _storage = LocalStorage(await SharedPreferences.getInstance());
  await _storage.setString(UserLocalDataIsolation.ownerKey, owner);
  final premium = MockPremiumRepository(
    _storage,
    secureStorage: InMemorySecureStorage(),
    ownerAccessAllowed: () =>
        _storage.getString(UserLocalDataIsolation.ownerKey) == owner,
  );
  await premium.savePurchaseCredentials(_creds);
  await premium.activatePlan(PremiumPlanKind.monthly, authoritative: true);
  return premium;
}

PremiumEntitlementReconciler _reconciler(
  MockPremiumRepository premium,
  _Backend backend,
) =>
    PremiumEntitlementReconciler(
      premium: premium,
      purchaseConfigured: true,
      verifier: backend.verifier(),
      forceReleaseMode: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('precondition: the subscriber is verified, active and has proof',
      () async {
    final premium = await _verifiedSubscriber();
    expect(await premium.isPremiumActive(), isTrue);
    expect(premium.wasAuthoritativelyVerified, isTrue);
    expect(await premium.readPurchaseCredentials(), isNotNull);
  });

  group('verification infrastructure unavailable — preserve verified Premium',
      () {
    for (final entry in {
      'auth_required (own-backend 401)': _authRequired,
      'provider_not_configured (no store credentials deployed)':
          _providerNotConfigured,
    }.entries) {
      test('${entry.key}: verified subscriber keeps Premium, proof and a '
          'retryable (non-definitive) refresh', () async {
        final premium = await _verifiedSubscriber();
        final backend = _Backend()..reply = entry.value;

        final snap = await _reconciler(premium, backend).reconcile();

        expect(backend.calls, 1, reason: 'the real verifier was consulted');
        expect(await premium.readPurchaseCredentials(), isNotNull,
            reason: 'purchase proof must never be retired here');
        expect(snap.entitlement, PremiumEntitlementState.active,
            reason: 'Apple/Google never judged this purchase');
        expect(await premium.isPremiumActive(), isTrue);
        expect(premium.wasAuthoritativelyVerified, isTrue);
        expect(snap.definitive, isFalse,
            reason: 'must stay retryable, not advance freshness');
      });

      test('${entry.key}: Premium gate (controller) stays open and the next '
          'successful refresh re-confirms definitively', () async {
        final premium = await _verifiedSubscriber();
        final backend = _Backend()..reply = entry.value;
        final service = PremiumService(
          premium,
          MockUserRepository(_storage),
          _NoopPort(),
          backend.verifier(),
        )..forceReleaseMode = true;
        final controller = PremiumStatusController(service);

        await controller.load();
        expect(controller.isPremium, isTrue,
            reason: 'a verified subscriber must not be locked out');
        expect(controller.isFresh, isFalse,
            reason: 'an unconfirmed refresh is not a definitive verdict');

        backend.reply = _active;
        final snap = await _reconciler(premium, backend).reconcile();
        expect(snap.entitlement, PremiumEntitlementState.active);
        expect(snap.definitive, isTrue);
      });
    }
  });

  group('freshness / retry contract for unavailable verification', () {
    for (final entry in {
      'auth_required': _authRequired,
      'provider_not_configured': _providerNotConfigured,
    }.entries) {
      test('${entry.key}: no definitive freshness, throttled (bounded) retry, '
          'and the next legitimate refresh re-confirms active', () async {
        final premium = await _verifiedSubscriber();
        final backend = _Backend()..reply = entry.value;
        var now = DateTime.utc(2026, 10, 4, 20);
        final service = PremiumService(
          premium,
          MockUserRepository(_storage),
          _NoopPort(),
          backend.verifier(),
        )..forceReleaseMode = true;
        final controller = PremiumStatusController(service, now: () => now);

        await controller.load();
        expect(backend.calls, 1);
        expect(controller.isPremium, isTrue);
        expect(controller.lastDefinitiveReconciledAt, isNull,
            reason: 'no 120s definitive verdict for an unavailable verifier');
        expect(controller.isFresh, isFalse);

        // Inside the retry throttle: no extra verify (no uncontrolled loop).
        now = now.add(const Duration(seconds: 1));
        await controller.ensureFresh();
        await controller.ensureFresh();
        expect(backend.calls, 1, reason: 'retry is throttled, not looping');
        expect(controller.isPremium, isTrue);

        // Past the throttle, far inside the 120s window: the legitimate
        // refresh runs again (it would not if freshness had been advanced).
        now = now.add(PremiumStatusController.retryThrottle);
        backend.reply = _active;
        await controller.ensureFresh();
        expect(backend.calls, 2);
        expect(controller.entitlement, PremiumEntitlementState.active);
        expect(controller.isPremium, isTrue);
        expect(controller.isFresh, isTrue);
        expect(await premium.isPremiumActive(), isTrue);
        expect(premium.wasAuthoritativelyVerified, isTrue);
        expect(await premium.readPurchaseCredentials(), isNotNull);
      });
    }
  });

  group('definitive store verdicts still demote (guards)', () {
    for (final entry in {
      'expired': _expired,
      'revoked': _revoked,
    }.entries) {
      test('${entry.key}: verified subscriber loses Premium', () async {
        final premium = await _verifiedSubscriber();
        final backend = _Backend()..reply = entry.value;

        final snap = await _reconciler(premium, backend).reconcile();

        expect(snap.entitlement, PremiumEntitlementState.inactive);
        expect(await premium.isPremiumActive(), isFalse);
      });
    }
  });

  test('owner isolation guard: an account switch during the refresh never '
      'lets the old owner\'s result grant Premium to the new owner', () async {
    await installTestPathProvider('oracly-wave13-owner-');
    final premium = await _verifiedSubscriber(owner: 'user-a');
    // Real account-switch lifecycle: a different user signs in on this device
    // while user-a's refresh is in flight (local data wipe + new owner).
    final isolation = UserLocalDataIsolation(
      _storage,
      secureStorage: InMemorySecureStorage(),
    );
    final backend = _Backend()
      ..reply = _active
      ..onCall = () async {
        await isolation.onSignedIn('user-b');
      };

    try {
      await _reconciler(premium, backend).reconcile();
    } catch (_) {
      // A fail-closed owner boundary is an acceptable outcome here.
    }

    expect(_storage.getString(UserLocalDataIsolation.ownerKey), 'user-b');
    final asUserB = MockPremiumRepository(
      _storage,
      secureStorage: InMemorySecureStorage(),
      ownerAccessAllowed: () =>
          _storage.getString(UserLocalDataIsolation.ownerKey) == 'user-b',
    );
    expect(await asUserB.isPremiumActive(), isFalse,
        reason: 'user-a\'s refresh must not leave Premium for user-b');
    expect(asUserB.wasAuthoritativelyVerified, isFalse);
    expect(await asUserB.readPurchaseCredentials(), isNull,
        reason: 'user-a proof is not visible to user-b');
    expect(await premium.isPremiumActive(), isFalse,
        reason: 'user-a\'s repository is no longer the active owner');
  });
}
