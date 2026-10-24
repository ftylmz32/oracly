/// Premium membership service — grants only after verification policy.
///
/// HONESTY: Local cache and debug overrides are not production receipt
/// validation. Apple/Google payment security is not solved here.
library;

import 'package:flutter/foundation.dart';

import '../../features/premium/models/premium_purchase_result.dart';
import '../../features/premium/models/premium_store_pending.dart';
import '../../features/premium/models/review_access_result.dart';
import '../../features/premium/services/local_cache_entitlement_verifier.dart';
import '../../features/premium/services/premium_entitlement_verifier.dart';
import '../../features/premium/services/premium_purchase_port.dart';
import '../../features/premium/services/review_access_service.dart';
import '../../features/premium/services/unavailable_premium_purchase.dart';
import '../auth/account_deletion_pending_state.dart';
import '../auth/user_local_data_isolation.dart';
import '../data/repositories/review_access_repository.dart';
import '../domain/models/premium_plan.dart';
import '../domain/repositories/premium_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'premium_entitlement_reconciler.dart';
import 'premium_grant_policy.dart';

class PremiumService {
  PremiumService(
    this._premium,
    this._user, [
    this._purchase = const UnavailablePremiumPurchase(),
    PremiumEntitlementVerifier? verifier,
    ReviewAccessRepository? reviewAccessRepository,
    ReviewAccessService? reviewAccessService,
  ]) : _verifier = verifier ?? const LocalCacheEntitlementVerifier(),
       _reviewAccessRepository = reviewAccessRepository,
       _reviewAccessService = reviewAccessService;

  final PremiumRepository _premium;
  final UserRepository _user;
  final PremiumPurchasePort _purchase;
  final PremiumEntitlementVerifier _verifier;
  final ReviewAccessRepository? _reviewAccessRepository;
  final ReviewAccessService? _reviewAccessService;

  /// Test-only: block unverified grants as release would.
  @visibleForTesting
  bool forceReleaseMode = false;

  PremiumEntitlementVerifier get verifier => _verifier;
  bool get purchaseConfigured => _purchase.isConfigured;
  bool get canAttemptRestore => _purchase.canAttemptRestore;
  bool get isActiveNow => AccountDeletionPendingState.allowsOwnerBoundExperience
      ? _premium.isActiveNow
      : false;
  bool get wasAuthoritativelyVerified => _premium.wasAuthoritativelyVerified;
  bool get ownerAccessReady => _premium is PremiumOwnerBoundary
      ? (_premium as PremiumOwnerBoundary).ownerAccessReady
      : true;

  Future<bool> isActive() async {
    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return false;
    return _premium.isPremiumActive();
  }

  Future<PremiumPlanKind?> activePlan() => _premium.activePlan();

  PremiumGrantPolicy get _grants => PremiumGrantPolicy(
    premium: _premium,
    user: _user,
    verifier: _verifier,
    forceReleaseMode: forceReleaseMode,
  );

  Future<void> preparePurchase() async {
    await _purchase.prepare();
    final late = await _purchase.consumeUnsolicitedGrant();
    if (late != null && late.granted && late.plan != null) {
      await _grants.applyStoreOutcome(late);
    }
  }

  Future<List<PremiumPlanModel>> getPlans() async {
    final plans = await _premium.getPlans();
    return [
      for (final plan in plans)
        PremiumPlanModel(
          kind: plan.kind,
          label: plan.label,
          price: _purchase.priceLabel(plan.kind) ?? plan.price,
          subtitle: plan.subtitle,
          isActive: plan.isActive,
        ),
    ];
  }

  /// The store port exposes a price only for products it actually returned.
  bool storeReturned(PremiumPlanKind kind) =>
      _purchase.isConfigured && _purchase.priceLabel(kind) != null;

  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    // Defence in depth below any UI state: an unfinished store transaction
    // or a saved, unresolved receipt means money may already be on its way.
    // No plan, tap or restart may start another payment until it settles.
    if (await _holdsUnresolvedPurchase()) {
      return PremiumPurchaseResult.pending();
    }
    return _grants.applyStoreOutcome(await _purchase.purchase(plan));
  }

  Future<bool> _holdsUnresolvedPurchase() async {
    if (await _readStorePending() != null) return true;
    final creds = await _premium.readPurchaseCredentials();
    return creds != null && creds.isComplete && !_premium.isActiveNow;
  }

  Future<PremiumStorePending?> _readStorePending() async {
    final premium = _premium;
    if (premium is! PremiumStorePendingStore) return null;
    return (premium as PremiumStorePendingStore).readStorePending();
  }

  Future<PremiumPurchaseResult> restore() async {
    return _grants.applyStoreOutcome(await _purchase.restore());
  }

  /// [scanStore] also re-reads the store's own purchase list (load and a
  /// user's status check); with a recorded unfinished transaction it is
  /// always re-read. [userInitiated] is the only case where a successful
  /// read that no longer lists the transaction releases the hold: an empty
  /// or failed automatic read never counts as a decline.
  Future<PremiumReconcileSnapshot> reconcile({
    bool forceReleaseMode = false,
    bool scanStore = false,
    bool userInitiated = false,
  }) async {
    await _refreshStore(scanStore: scanStore, userInitiated: userInitiated);
    return PremiumEntitlementReconciler(
      premium: _premium,
      purchaseConfigured: purchaseConfigured,
      canAttemptRestore: canAttemptRestore,
      verifier: _verifier,
      forceReleaseMode: forceReleaseMode || this.forceReleaseMode,
    ).reconcile();
  }

  Future<void> _refreshStore({
    required bool scanStore,
    required bool userInitiated,
  }) async {
    final port = _purchase;
    if (port is! StorePurchaseRefresher) return;
    if (_premium.isActiveNow && _premium.wasAuthoritativelyVerified) return;
    final recorded = await _readStorePending();
    if (recorded == null && !scanStore && !userInitiated) return;

    final unfinished =
        await (port as StorePurchaseRefresher).refreshStorePurchases();
    // A purchase the store finished while we were away was saved and
    // acknowledged by the refresh; verify it like any late delivery.
    final late = await _purchase.consumeUnsolicitedGrant();
    if (late != null && late.granted && late.plan != null) {
      await _grants.applyStoreOutcome(late);
    }
    if (unfinished == null) return; // store unreadable: keep what we have
    if (unfinished.isNotEmpty) {
      if (recorded == null) await _recordStorePending(unfinished.first);
      return;
    }
    if (recorded != null && userInitiated) {
      // The store answered and no longer lists the transaction as pending
      // or newly finished: it was declined or cancelled while we were away.
      await _clearStorePending(recorded.productId);
    }
  }

  Future<void> _recordStorePending(String productId) {
    return UserLocalDataIsolation.runOwnerScopedMutation(() async {
      final premium = _premium;
      if (premium is! PremiumStorePendingStore || !ownerAccessReady) return;
      await (premium as PremiumStorePendingStore).saveStorePending(
        PremiumStorePending(
          platform: defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          productId: productId,
          sinceUtc: DateTime.now().toUtc(),
        ),
      );
    });
  }

  Future<void> _clearStorePending(String productId) {
    return UserLocalDataIsolation.runOwnerScopedMutation(() async {
      final premium = _premium;
      if (premium is! PremiumStorePendingStore || !ownerAccessReady) return;
      final store = premium as PremiumStorePendingStore;
      if ((await store.readStorePending())?.productId != productId) return;
      await store.clearStorePending();
    });
  }

  /// Google Play / App Store closed-test reviewer entitlement — entirely
  /// separate from commerce Premium. Never reads or writes [_premium]'s
  /// purchase credentials or active-plan state. Re-checks the stored code
  /// against the backend every call (self-healing): a *definitive* server
  /// denial (wrong/disabled code) clears the local flag — no client update
  /// required to revoke reviewer access. A transient failure (network,
  /// timeout, cold-start connectivity, unexpected response shape) must
  /// never clear a previously-proven grant — only preserve it and retry on
  /// the next reconcile, or a flaky connection would silently revoke a
  /// valid reviewer on every app restart.
  Future<bool> reviewAccessActive() async {
    final repo = _reviewAccessRepository;
    if (repo == null || !repo.isGrantedLocally) return false;
    final service = _reviewAccessService;
    if (service == null || !service.isConfigured) return repo.isGrantedLocally;
    final code = await repo.readStoredCode();
    if (code == null || code.isEmpty) {
      await repo.clear();
      return false;
    }
    final result = await service.activate(code);
    if (result.granted) return true;
    if (!result.definitive) return true;
    if (!_reviewOwnerReady) return true;
    await UserLocalDataIsolation.runOwnerScopedMutation(() async {
      if (!_reviewOwnerReady) return;
      await repo.clear();
    });
    return false;
  }

  /// Submits a reviewer-entered code. On success, persists it locally so
  /// [reviewAccessActive] can keep self-validating on every reconcile.
  /// Returns the full [ReviewAccessResult] — not just whether it granted —
  /// so a caller can tell a real "wrong code" denial (definitive) apart from
  /// a transient network/server failure (not definitive) and word the
  /// message honestly instead of always saying the code is wrong. Also
  /// reports non-definitive if the server said yes but the client could not
  /// actually persist it — telling the UI success in that case would not
  /// survive an app restart.
  Future<ReviewAccessResult> activateReviewAccessResult(String code) async {
    final service = _reviewAccessService;
    final repo = _reviewAccessRepository;
    if (service == null || repo == null) {
      return ReviewAccessResult.denied('not_configured');
    }
    final result = await service.activate(code);
    if (!result.granted) return result;
    if (!_reviewOwnerReady) {
      return ReviewAccessResult.denied('owner_changed', definitive: false);
    }
    final persisted = await UserLocalDataIsolation.runOwnerScopedMutation(
      () async {
        if (!_reviewOwnerReady) return false;
        return repo.markGranted(code);
      },
    );
    if (!persisted) {
      return ReviewAccessResult.denied(
        'local_persist_failed',
        definitive: false,
      );
    }
    return result;
  }

  bool get _reviewOwnerReady {
    final premium = _premium;
    if (premium is PremiumOwnerBoundary) {
      return (premium as PremiumOwnerBoundary).ownerAccessReady;
    }
    return true;
  }

  /// Convenience wrapper over [activateReviewAccessResult] for callers that
  /// only care whether access was granted.
  Future<bool> activateReviewAccess(String code) async {
    return (await activateReviewAccessResult(code)).granted;
  }
}
