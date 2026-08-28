/// Count and recency of one real source. Never invented.
library;

class DiscoverySourceActivity {
  const DiscoverySourceActivity({
    required this.source,
    required this.count,
    required this.lastAt,
    this.recentCount = 0,
  });

  final String source;
  final int count;
  final DateTime lastAt;

  /// Records inside the last 7 days — not lifetime total.
  final int recentCount;
}
