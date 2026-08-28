/// Compares dominant themes across earlier vs recent halves of a period.
library;

import '../models/discovery_observation.dart';
import '../models/theme_over_time_comparison.dart';
import '../models/theme_over_time_period.dart';

abstract final class ThemeOverTimeBuilder {
  ThemeOverTimeBuilder._();

  static const minTotal = 4;
  static const minPerHalf = 2;

  static List<ThemeOverTimeComparison> fromObservations(
    List<DiscoveryObservation> observations, {
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final results = <ThemeOverTimeComparison>[];
    for (final period in ThemeOverTimePeriod.values) {
      final comparison = _compare(observations, period, anchor);
      if (comparison != null) results.add(comparison);
    }
    return results;
  }

  static ThemeOverTimeComparison? _compare(
    List<DiscoveryObservation> observations,
    ThemeOverTimePeriod period,
    DateTime now,
  ) {
    final start = now.subtract(Duration(days: period.dayCount));
    final inPeriod = observations
        .where(
          (o) =>
              !o.observedAt.isBefore(start) && !o.observedAt.isAfter(now),
        )
        .toList();
    if (inPeriod.length < minTotal) return null;

    final times = inPeriod.map((o) => o.observedAt).toList()..sort();
    final span = times.last.difference(times.first);
    if (span.inDays < period.dayCount ~/ 3) return null;

    final mid = start.add(now.difference(start) ~/ 2);
    final earlierObs =
        inPeriod.where((o) => o.observedAt.isBefore(mid)).toList();
    final recentObs =
        inPeriod.where((o) => !o.observedAt.isBefore(mid)).toList();
    if (earlierObs.length < minPerHalf || recentObs.length < minPerHalf) {
      return null;
    }

    final earlier = _dominantWindow(earlierObs);
    final recent = _dominantWindow(recentObs);
    if (earlier == null || recent == null) return null;

    return ThemeOverTimeComparison(
      period: period,
      earlier: earlier,
      recent: recent,
      themesDiffer: earlier.theme != recent.theme,
    );
  }

  static ThemeOverTimeWindow? _dominantWindow(
    List<DiscoveryObservation> observations,
  ) {
    final counts = <String, int>{};
    for (final o in observations) {
      counts[o.theme] = (counts[o.theme] ?? 0) + 1;
    }
    String? theme;
    var bestCount = 0;
    DateTime? bestAt;
    for (final entry in counts.entries) {
      final latest = observations
          .where((o) => o.theme == entry.key)
          .map((o) => o.observedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final wins = entry.value > bestCount ||
          (entry.value == bestCount &&
              bestAt != null &&
              latest.isAfter(bestAt));
      if (wins) {
        theme = entry.key;
        bestCount = entry.value;
        bestAt = latest;
      }
    }
    if (theme == null) return null;
    final sources = {
      for (final o in observations.where((o) => o.theme == theme)) o.source,
    }.toList()
      ..sort();
    return ThemeOverTimeWindow(
      theme: theme,
      sightingCount: bestCount,
      sources: sources,
    );
  }
}
