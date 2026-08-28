/// Recency weights for discovery observations. Never erases history.
library;

abstract final class DiscoveryRecency {
  DiscoveryRecency._();

  static double weight(DateTime observedAt, DateTime now) {
    final days = now.difference(observedAt).inDays;
    if (days <= 7) return 1.0;
    if (days <= 30) return 0.55;
    if (days <= 90) return 0.22;
    return 0.08;
  }
}
