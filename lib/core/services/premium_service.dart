/// Premium membership service — grants only after verification policy.
///
/// HONESTY: Local cache and debug overrides are not production receipt
/// validation. Apple/Google payment security is not solved here.
library;

import 'package:flutter/foundation.dart';

import '../../features/premium/models/premium_purchase_result.dart';
import '../../features/premium/services/local_cache_entitlement_verifier.dart';
import '../../features/premium/services/premium_entitlement_verifier.dart';
import '../../features/premium/services/premium_purchase_port.dart';
import '../../features/premium/services/review_access_service.dart';
import '../../features/premium/services/unavailable_premium_purchase.dart';
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
  bool get isActiveNow => _premium.isActiveNow;
  bool get wasAuthoritativelyVerified => _premium.wasAuthoritativelyVerified;

  Future<bool> isActive() => _premium.isPremiumActive();
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

  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    return _grants.applyStoreOutcome(await _purchase.purchase(plan));
  }

  Future<PremiumPurchaseResult> restore() async {
    return _grants.applyStoreOutcome(await _purchase.restore());
  }

  Future<PremiumReconcileSnapshot> reconcile({
    bool forceReleaseMode = false,
  }) {
    return PremiumEntitlementReconciler(
      premium: _premium,
      purchaseConfigured: purchaseConfigured,
      canAttemptRestore: canAttemptRestore,
      verifier: _verifier,
      forceReleaseMode: forceReleaseMode || this.forceReleaseMode,
    ).reconcile();
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
    await repo.clear();
    return false;
  }

  /// Submits a reviewer-entered code. On success, persists it locally so
  /// [reviewAccessActive] can keep self-validating on every reconcile.
  /// Returns false (not "granted") if the server said yes but the client
  /// could not actually persist it — telling the UI success in that case
  /// would not survive an app restart.
  Future<bool> activateReviewAccess(String code) async {
    final service = _reviewAccessService;
    final repo = _reviewAccessRepository;
    if (service == null || repo == null) return false;
    final result = await service.activate(code);
    if (!result.granted) return false;
    return repo.markGranted(code);
  }
}
