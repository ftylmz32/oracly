/// R3.1 — definitive entitlement freshness vs transient retry throttle.
library;

/// Separates authoritative Premium freshness from attempt throttling.
///
/// Only a definitive reconcile (active / inactive / expired / unverified
/// conclusion) advances [lastDefinitiveAt]. Transient verification failures
/// update [lastAttemptAt] only so storms are bounded without pretending
/// the entitlement was freshly confirmed.
class PremiumReconcileFreshness {
  PremiumReconcileFreshness();

  /// How long a definitive reconciliation may be trusted.
  static const freshnessWindow = Duration(seconds: 120);

  /// Minimum gap between reconcile *attempts* after a transient result.
  static const retryThrottle = Duration(seconds: 20);

  DateTime? lastDefinitiveAt;
  DateTime? lastAttemptAt;

  bool isFresh(DateTime now) =>
      lastDefinitiveAt != null &&
      now.difference(lastDefinitiveAt!) < freshnessWindow;

  bool isRetryThrottled(DateTime now) =>
      lastAttemptAt != null &&
      now.difference(lastAttemptAt!) < retryThrottle;

  void recordAttempt({required bool definitive, required DateTime now}) {
    lastAttemptAt = now;
    if (definitive) lastDefinitiveAt = now;
  }

  void invalidateDefinitive() {
    lastDefinitiveAt = null;
  }

  /// Used by [forceReconcile] — clears definitive freshness and throttle.
  void bypassCaches() {
    lastDefinitiveAt = null;
    lastAttemptAt = null;
  }
}
