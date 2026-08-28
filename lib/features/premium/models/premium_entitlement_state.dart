/// Commerce-backed Premium entitlement — never a UI-only flag.
library;

enum PremiumEntitlementState {
  /// Verified Premium membership from the entitlement layer.
  active,

  /// Store is available; membership is not active.
  inactive,

  /// A purchase is in flight with the store.
  pending,

  /// A restore is in flight with the store.
  restoring,

  /// Store commerce is not configured / not available.
  unavailable,

  /// Purchase evidence exists but was not authoritatively verified.
  /// Does not unlock Premium features.
  unverified,

  /// Load, purchase, or restore failed in the commerce layer.
  error,
}

extension PremiumEntitlementStateX on PremiumEntitlementState {
  bool get allowsPremiumFeatures => this == PremiumEntitlementState.active;

  bool get isTransient =>
      this == PremiumEntitlementState.pending ||
      this == PremiumEntitlementState.restoring;

  bool get canStartPurchase =>
      this == PremiumEntitlementState.inactive ||
      this == PremiumEntitlementState.unverified ||
      this == PremiumEntitlementState.error;

  bool get canStartRestore =>
      this == PremiumEntitlementState.inactive ||
      this == PremiumEntitlementState.unverified ||
      this == PremiumEntitlementState.error;
}
