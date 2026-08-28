/// Premium repository interface — local cache + optional verify metadata.
library;

import '../../../features/premium/models/premium_purchase_credentials.dart';
import '../models/premium_plan.dart';

abstract class PremiumRepository {
  Future<bool> isPremiumActive();

  /// Synchronous read of the persisted Free / Premium flag.
  bool get isActiveNow;

  /// True only after a verifier returned [active] and we granted authoritatively.
  /// Local/debug grants must leave this false.
  bool get wasAuthoritativelyVerified;

  Future<PremiumPlanKind?> activePlan();

  Future<void> activatePlan(
    PremiumPlanKind plan, {
    bool authoritative = false,
  });

  /// Clears local Premium access without inventing a store revoke.
  Future<void> clearLocalPremiumAccess();

  Future<void> savePurchaseCredentials(PremiumPurchaseCredentials credentials);

  PremiumPurchaseCredentials? readPurchaseCredentials();

  Future<List<PremiumPlanModel>> getPlans();
}
