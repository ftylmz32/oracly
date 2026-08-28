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
import '../../features/premium/services/unavailable_premium_purchase.dart';
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
  ]) : _verifier = verifier ?? const LocalCacheEntitlementVerifier();

  final PremiumRepository _premium;
  final UserRepository _user;
  final PremiumPurchasePort _purchase;
  final PremiumEntitlementVerifier _verifier;

  /// Test-only: block unverified grants as release would.
  @visibleForTesting
  bool forceReleaseMode = false;

  PremiumEntitlementVerifier get verifier => _verifier;
  bool get purchaseConfigured => _purchase.isConfigured;
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
      verifier: _verifier,
      forceReleaseMode: forceReleaseMode || this.forceReleaseMode,
    ).reconcile();
  }
}
