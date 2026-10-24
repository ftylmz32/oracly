/// A purchase the store itself reported as not finished yet (Play PENDING,
/// a slow payment or an expired wait for the store's answer). It is NOT
/// proof of payment: it holds no token or receipt, grants nothing and is
/// never sent for verification. It only stops a second purchase from
/// starting until the store gives a terminal answer.
library;

class PremiumStorePending {
  const PremiumStorePending({
    required this.platform,
    required this.productId,
    required this.sinceUtc,
  });

  final String platform;
  final String productId;
  final DateTime sinceUtc;
}

/// Which kind of unresolved purchase holds new payments.
enum PremiumPendingKind {
  /// The store has not finished the transaction (no receipt yet).
  store,

  /// The store finished it; the saved receipt awaits a backend verdict.
  verification,
}
