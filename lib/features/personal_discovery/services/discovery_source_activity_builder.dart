/// Derives source activity from persisted records only.
library;

import '../models/discovery_source_activity.dart';
import '../models/personal_discovery_sources.dart';

abstract final class DiscoverySourceActivityBuilder {
  DiscoverySourceActivityBuilder._();

  static const recentDays = 7;

  static List<DiscoverySourceActivity> from(
    PersonalDiscoverySources sources, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    return [
      ?_row('tarot', sources.readings.map((r) => r.createdAt), clock),
      ?_row(
        'dream',
        sources.dreams.map((d) => d.updatedAt ?? d.createdAt),
        clock,
      ),
      ?_row('coffee', sources.coffee.map((c) => c.createdAt), clock),
      ?_row(
        'reflection',
        sources.conversations
            .where((c) => c.messagesJson.isNotEmpty)
            .map((c) => c.updatedAt),
        clock,
      ),
      ?_row('palm', sources.palm.map((p) => p.createdAt), clock),
      ?_row('astrology', sources.astrology.map((a) => a.date), clock),
      ?_row('daily', sources.dailyMessages.map((d) => d.day), clock),
      if (sources.starChart != null)
        _row(
          'starMap',
          [
            sources.starChart!.updatedAt ?? sources.starChart!.createdAt,
          ],
          clock,
        )!,
    ];
  }

  static DiscoverySourceActivity? _row(
    String source,
    Iterable<DateTime> stamps,
    DateTime now,
  ) {
    final dates = stamps.toList();
    if (dates.isEmpty) return null;
    final last = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final recent = dates
        .where(
          (at) => !at.isAfter(now) && now.difference(at).inDays <= recentDays,
        )
        .length;
    return DiscoverySourceActivity(
      source: source,
      count: dates.length,
      lastAt: last,
      recentCount: recent,
    );
  }
}
