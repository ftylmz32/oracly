/// Premium purchase integrity — orphaned purchase recovery.
///
/// A store purchase can be acknowledged (completePurchase) while the first
/// backend verification fails transiently. These tests prove the store proof
/// survives as UNVERIFIED recovery material that never grants Premium by
/// itself, is re-verified on a later reconcile without a Restore tap, is
/// retired only on a definitive backend verdict, and stays owner-scoped.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_entitlement_reconciler.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/storage/secure_storage.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/premium/services/store_iap_client.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ScriptedVerifier implements PremiumEntitlementVerifier {
  _ScriptedVerifier(this._results);

  final List<PremiumVerifyResult> _results;
  int calls = 0;
  final List<String> tokensSeen = [];

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    tokensSeen.add(purchaseToken);
    final result = _results[calls.clamp(0, _results.length - 1)];
    calls++;
    return result;
  }
}

class _FakeIap implements StoreIapClient {
  _FakeIap({this.products = const []});

  final List<ProductDetails> products;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  int completeCalls = 0;
  final List<String> order = [];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: products,
    notFoundIDs: identifiers
        .where((id) => products.every((p) => p.id != id))
        .toList(),
  );

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCalls++;
    order.add('complete');
  }

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  void dispose() => _controller.close();
}

ProductDetails _product(String id) => ProductDetails(
  id: id,
  title: 'Premium',
  description: 'Premium',
  price: 'TRY 100',
  rawPrice: 100,
  currencyCode: 'TRY',
);

PurchaseDetails _event(
  String productId, {
  String token = 'store-token',
  String txn = 'txn-1',
  PurchaseStatus status = PurchaseStatus.purchased,
}) => PurchaseDetails(
  purchaseID: txn,
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: token,
    source: 'store',
  ),
  transactionDate: '1',
  status: status,
)..pendingCompletePurchase = true;

const _monthly = PremiumPurchaseCredentials(
  platform: 'android',
  productId: PremiumStoreCatalog.monthlyId,
  purchaseToken: 'orphaned-token',
  transactionId: 'orphaned-txn',
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late SecureStorage secure;
  late MockPremiumRepository repo;

  PremiumEntitlementReconciler reconcilerFor(
    PremiumEntitlementVerifier verifier, {
    MockPremiumRepository? premium,
  }) => PremiumEntitlementReconciler(
    premium: premium ?? repo,
    purchaseConfigured: true,
    verifier: verifier,
    forceReleaseMode: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
    repo = MockPremiumRepository(storage, secureStorage: secure);
  });

  group('store terminal events persist recovery material', () {
    test('credentials persist BEFORE completePurchase and never grant', () async {
      final iap = _FakeIap(products: [_product(PremiumStoreCatalog.monthlyId)]);
      addTearDown(iap.dispose);
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: (creds) async {
          iap.order.add('persist');
          await repo.savePurchaseCredentials(creds);
        },
      );
      await port.prepare();
      final future = port.purchase(PremiumPlanKind.monthly);
      iap.emit([_event(PremiumStoreCatalog.monthlyId)]);
      final result = await future;

      expect(result.granted, isTrue);
      expect(iap.order, ['persist', 'complete']);
      expect((await repo.readPurchaseCredentials())?.purchaseToken, 'store-token');
      expect(await repo.isPremiumActive(), isFalse);
      expect(repo.wasAuthoritativelyVerified, isFalse);
    });

    test('restored event persists too, with an empty product catalogue', () async {
      final iap = _FakeIap();
      addTearDown(iap.dispose);
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: repo.savePurchaseCredentials,
      );
      await port.prepare();
      expect(port.isConfigured, isFalse);
      expect(port.canAttemptRestore, isTrue);
      final future = port.restore();
      iap.emit([
        _event(
          PremiumStoreCatalog.yearlyId,
          token: 'restored-token',
          status: PurchaseStatus.restored,
        ),
      ]);
      final result = await future;

      expect(result.outcome, PremiumPurchaseOutcome.restored);
      expect(
        (await repo.readPurchaseCredentials())?.purchaseToken,
        'restored-token',
      );
      expect(await repo.isPremiumActive(), isFalse);
    });

    test('delayed event after the session ended is persisted and kept for '
        'prepare, then recovered after restart', () async {
      final iap = _FakeIap(products: [_product(PremiumStoreCatalog.monthlyId)]);
      addTearDown(iap.dispose);
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: repo.savePurchaseCredentials,
      );
      await port.prepare();
      // No purchase() waiter is active.
      iap.emit([_event(PremiumStoreCatalog.monthlyId, token: 'late-token')]);
      await _flush();

      expect(iap.completeCalls, 1);
      final late = await port.consumeUnsolicitedGrant();
      expect(late?.granted, isTrue);
      expect(await repo.isPremiumActive(), isFalse);

      // Restart: fresh repository instance on the same storage.
      final restarted = MockPremiumRepository(storage, secureStorage: secure);
      final verifier = _ScriptedVerifier([PremiumVerifyResult.active('ok')]);
      final snap = await reconcilerFor(verifier, premium: restarted).reconcile();

      expect(snap.entitlement, PremiumEntitlementState.active);
      expect(verifier.tokensSeen, ['late-token']);
      expect(await restarted.activePlan(), PremiumPlanKind.monthly);
    });

    test('cancelled and store-error events persist nothing', () async {
      final iap = _FakeIap(products: [_product(PremiumStoreCatalog.monthlyId)]);
      addTearDown(iap.dispose);
      var persists = 0;
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: (_) async => persists++,
      );
      await port.prepare();

      final cancelled = port.purchase(PremiumPlanKind.monthly);
      iap.emit([
        _event(PremiumStoreCatalog.monthlyId, status: PurchaseStatus.canceled),
      ]);
      expect((await cancelled).outcome, PremiumPurchaseOutcome.cancelled);

      final failed = port.purchase(PremiumPlanKind.monthly);
      iap.emit([
        _event(PremiumStoreCatalog.monthlyId, status: PurchaseStatus.error),
      ]);
      expect((await failed).outcome, PremiumPurchaseOutcome.failed);

      expect(persists, 0);
      expect(iap.completeCalls, 0);
      expect(await repo.readPurchaseCredentials(), isNull);
    });

    test('duplicate delivery is idempotent and never grants', () async {
      final iap = _FakeIap(products: [_product(PremiumStoreCatalog.monthlyId)]);
      addTearDown(iap.dispose);
      var persists = 0;
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: (creds) async {
          persists++;
          await repo.savePurchaseCredentials(creds);
        },
      );
      await port.prepare();
      final future = port.purchase(PremiumPlanKind.monthly);
      iap.emit([
        _event(PremiumStoreCatalog.monthlyId),
        _event(PremiumStoreCatalog.monthlyId),
      ]);
      await future;
      await _flush();

      expect(persists, 2);
      expect((await repo.readPurchaseCredentials())?.purchaseToken, 'store-token');
      expect(await repo.isPremiumActive(), isFalse);
    });

    test('a failing recovery write never blocks store completion', () async {
      final iap = _FakeIap(products: [_product(PremiumStoreCatalog.monthlyId)]);
      addTearDown(iap.dispose);
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: (_) async => throw StateError('disk full'),
      );
      await port.prepare();
      final future = port.purchase(PremiumPlanKind.monthly);
      iap.emit([_event(PremiumStoreCatalog.monthlyId)]);

      expect((await future).granted, isTrue);
      expect(iap.completeCalls, 1);
    });

    test('iOS lifetime is never persisted as recovery material', () async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = original);
      final iap = _FakeIap();
      addTearDown(iap.dispose);
      var persists = 0;
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: (_) async => persists++,
      );
      await port.prepare();
      final future = port.restore();
      iap.emit([
        _event(PremiumStoreCatalog.lifetimeId, status: PurchaseStatus.restored),
      ]);
      await future;

      expect(persists, 0);
    });
  });

  group('purchase -> transient verify failure -> automatic recovery', () {
    test('first verify fails transiently; later reconcile grants from the '
        'surviving credentials without a Restore tap', () async {
      final iap = _FakeIap(products: [_product(PremiumStoreCatalog.monthlyId)]);
      addTearDown(iap.dispose);
      final verifier = _ScriptedVerifier([
        PremiumVerifyResult.error('http_503'),
        PremiumVerifyResult.active('subscription_active'),
      ]);
      final port = StorePremiumPurchase(
        client: iap,
        persistRetryCredentials: (creds) =>
            persistPurchaseRecovery(() => repo, creds),
      );
      final service = PremiumService(
        repo,
        MockUserRepository(storage),
        port,
        verifier,
      )..forceReleaseMode = true;
      await service.preparePurchase();

      final purchase = service.purchase(PremiumPlanKind.monthly);
      iap.emit([_event(PremiumStoreCatalog.monthlyId, token: 'paid-token')]);
      final first = await purchase;

      expect(first.outcome, PremiumPurchaseOutcome.unverified);
      expect(await repo.isPremiumActive(), isFalse);
      expect((await repo.readPurchaseCredentials())?.purchaseToken, 'paid-token');

      final snap = await service.reconcile(forceReleaseMode: true);

      expect(snap.entitlement, PremiumEntitlementState.active);
      expect(verifier.tokensSeen, ['paid-token', 'paid-token']);
      expect(await repo.isPremiumActive(), isTrue);
      expect(repo.wasAuthoritativelyVerified, isTrue);
    });

    test('recovery survives service/controller recreation', () async {
      await repo.savePurchaseCredentials(_monthly);
      final transient = await reconcilerFor(
        _ScriptedVerifier([PremiumVerifyResult.error('network_or_parse')]),
      ).reconcile();
      expect(transient.entitlement, PremiumEntitlementState.inactive);
      expect(transient.definitive, isFalse);

      final recreated = MockPremiumRepository(storage, secureStorage: secure);
      final snap = await reconcilerFor(
        _ScriptedVerifier([PremiumVerifyResult.active('ok')]),
        premium: recreated,
      ).reconcile();
      expect(snap.entitlement, PremiumEntitlementState.active);
      expect(await recreated.isPremiumActive(), isTrue);
    });

    test('a second reconcile after recovery does not re-grant from the '
        'recovery path', () async {
      await repo.savePurchaseCredentials(_monthly);
      final verifier = _ScriptedVerifier([PremiumVerifyResult.active('ok')]);
      final reconciler = reconcilerFor(verifier);
      expect(
        (await reconciler.reconcile()).entitlement,
        PremiumEntitlementState.active,
      );
      // Now authoritative: the existing refresh path runs, same single grant.
      expect(
        (await reconciler.reconcile()).entitlement,
        PremiumEntitlementState.active,
      );
      expect(verifier.calls, 2);
      expect(await repo.activePlan(), PremiumPlanKind.monthly);
    });

    test('no saved credentials -> no verify call at all', () async {
      final verifier = _ScriptedVerifier([PremiumVerifyResult.active('ok')]);
      final snap = await reconcilerFor(verifier).reconcile();
      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(verifier.calls, 0);
    });

    test('pending store settlement keeps credentials and never grants', () async {
      await repo.savePurchaseCredentials(_monthly);
      final snap = await reconcilerFor(
        _ScriptedVerifier([PremiumVerifyResult.pending('purchase_pending')]),
      ).reconcile();
      expect(snap.entitlement, PremiumEntitlementState.pending);
      expect(await repo.isPremiumActive(), isFalse);
      expect(await repo.readPurchaseCredentials(), isNotNull);
    });
  });

  group('definitive vs non-definitive backend verdicts', () {
    for (final result in [
      PremiumVerifyResult.error('network_or_parse'),
      PremiumVerifyResult.error('http_503'),
      PremiumVerifyResult.unverified('auth_required'),
      PremiumVerifyResult.unverified('provider_not_configured'),
      PremiumVerifyResult.unverified('transaction_not_found'),
      PremiumVerifyResult.unverified('unknown_status'),
    ]) {
      test('${result.status.name}/${result.reason} keeps credentials, no grant',
          () async {
        await repo.savePurchaseCredentials(_monthly);
        final snap = await reconcilerFor(_ScriptedVerifier([result])).reconcile();
        expect(snap.entitlement, PremiumEntitlementState.inactive);
        expect(snap.definitive, isFalse);
        expect(await repo.isPremiumActive(), isFalse);
        expect(await repo.readPurchaseCredentials(), isNotNull);
      });
    }

    for (final result in [
      PremiumVerifyResult.expired('subscription_expired'),
      PremiumVerifyResult.inactive('revoked'),
      PremiumVerifyResult.unverified('jws_invalid'),
      PremiumVerifyResult.unverified('platform_product_mismatch'),
      PremiumVerifyResult.unverified('purchase_bound_to_other_account'),
    ]) {
      test('${result.status.name}/${result.reason} retires credentials, no grant',
          () async {
        await repo.savePurchaseCredentials(_monthly);
        final snap = await reconcilerFor(_ScriptedVerifier([result])).reconcile();
        expect(snap.entitlement, PremiumEntitlementState.inactive);
        expect(await repo.isPremiumActive(), isFalse);
        expect(await repo.readPurchaseCredentials(), isNull);
      });
    }
  });

  group('owner isolation', () {
    MockPremiumRepository ownerBound(bool Function() allowed) =>
        MockPremiumRepository(
          storage,
          secureStorage: secure,
          ownerAccessAllowed: allowed,
        );

    test('recovery write for a non-isolated owner writes nothing', () async {
      final notReady = ownerBound(() => false);
      await persistPurchaseRecovery(() => notReady, _monthly);
      expect(await repo.readPurchaseCredentials(), isNull);
    });

    test('recovery write resolves the CURRENT owner repository at call time',
        () async {
      var owner = 'owner-a';
      final repoA = ownerBound(() => owner == 'owner-a');
      final repoB = ownerBound(() => owner == 'owner-b');
      MockPremiumRepository current() => owner == 'owner-a' ? repoA : repoB;

      owner = 'owner-b';
      await persistPurchaseRecovery(current, _monthly);
      expect((await repoB.readPurchaseCredentials())?.purchaseToken,
          'orphaned-token');
      expect(await repoA.readPurchaseCredentials(), isNull);
    });

    test('owner A recovery material is wiped at the account boundary and '
        'can never be verified for owner B', () async {
      await repo.savePurchaseCredentials(_monthly);
      await MockPremiumRepository.clearPersistedLocalState(
        storage,
        secureStorage: secure,
      );
      final ownerB = MockPremiumRepository(storage, secureStorage: secure);
      final verifier = _ScriptedVerifier([PremiumVerifyResult.active('ok')]);
      final snap = await reconcilerFor(verifier, premium: ownerB).reconcile();

      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(verifier.calls, 0);
      expect(await ownerB.isPremiumActive(), isFalse);
    });

    test('a non-isolated owner never reads or verifies recovery material',
        () async {
      await repo.savePurchaseCredentials(_monthly);
      final blocked = ownerBound(() => false);
      final verifier = _ScriptedVerifier([PremiumVerifyResult.active('ok')]);
      final snap = await reconcilerFor(verifier, premium: blocked).reconcile();

      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(verifier.calls, 0);
    });

    test('owner switch during verify -> no activation for the new owner',
        () async {
      var allowed = true;
      final bound = ownerBound(() => allowed);
      await bound.savePurchaseCredentials(_monthly);
      final verifier = _SwitchingVerifier(() => allowed = false);
      final snap = await reconcilerFor(verifier, premium: bound).reconcile();

      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(snap.definitive, isFalse);
      allowed = true;
      expect(await bound.isPremiumActive(), isFalse);
    });
  });

  group('per-platform recovery', () {
    for (final (platform, productId, plan) in [
      ('android', PremiumStoreCatalog.monthlyId, PremiumPlanKind.monthly),
      ('android', PremiumStoreCatalog.yearlyId, PremiumPlanKind.yearly),
      ('android', PremiumStoreCatalog.lifetimeId, PremiumPlanKind.lifetime),
      ('ios', PremiumStoreCatalog.monthlyId, PremiumPlanKind.monthly),
      ('ios', PremiumStoreCatalog.yearlyId, PremiumPlanKind.yearly),
    ]) {
      test('$platform $productId recovers to $plan', () async {
        await repo.savePurchaseCredentials(
          PremiumPurchaseCredentials(
            platform: platform,
            productId: productId,
            purchaseToken: '$platform-token',
            transactionId: '$platform-txn',
          ),
        );
        final snap = await reconcilerFor(
          _ScriptedVerifier([PremiumVerifyResult.active('ok')]),
        ).reconcile();
        expect(snap.entitlement, PremiumEntitlementState.active);
        expect(await repo.activePlan(), plan);
      });
    }

    test('iOS lifetime recovery material is retired by the server verdict',
        () async {
      await repo.savePurchaseCredentials(
        const PremiumPurchaseCredentials(
          platform: 'ios',
          productId: PremiumStoreCatalog.lifetimeId,
          purchaseToken: 'ios-lifetime',
          transactionId: 'ios-lifetime-txn',
        ),
      );
      final snap = await reconcilerFor(
        _ScriptedVerifier([
          PremiumVerifyResult.unverified('platform_product_mismatch'),
        ]),
      ).reconcile();
      expect(snap.entitlement, PremiumEntitlementState.inactive);
      expect(await repo.isPremiumActive(), isFalse);
      expect(await repo.readPurchaseCredentials(), isNull);
    });
  });
}

/// Returns active, but flips owner access off while "in flight".
class _SwitchingVerifier implements PremiumEntitlementVerifier {
  _SwitchingVerifier(this._onVerify);

  final void Function() _onVerify;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    _onVerify();
    return PremiumVerifyResult.active('ok');
  }
}
