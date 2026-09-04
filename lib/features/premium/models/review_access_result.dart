/// Google Play / App Store reviewer-access outcome — never a Premium purchase.
library;

class ReviewAccessResult {
  const ReviewAccessResult({
    required this.granted,
    this.reason,
    this.definitive = true,
  });

  final bool granted;
  final String? reason;

  /// True only when a reachable server explicitly answered `granted: false`
  /// (wrong/disabled code, or the feature not configured). False for network
  /// errors, timeouts, and malformed/unexpected responses — those must never
  /// be treated the same as a real revocation.
  final bool definitive;

  factory ReviewAccessResult.granted() =>
      const ReviewAccessResult(granted: true);

  factory ReviewAccessResult.denied(String reason, {bool definitive = true}) =>
      ReviewAccessResult(granted: false, reason: reason, definitive: definitive);
}
