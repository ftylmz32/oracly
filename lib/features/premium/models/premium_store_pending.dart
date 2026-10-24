/// Which kind of unresolved purchase holds new payments.
library;

enum PremiumPendingKind {
  /// The store has not finished the transaction for its owner yet (no
  /// receipt here), or finished it while another account was signed in.
  store,

  /// The store finished it; the saved receipt awaits a backend verdict.
  verification,
}
