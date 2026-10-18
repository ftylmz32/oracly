/// When the Home ritual window next changes, and whether a new reading matters.
library;

import 'oracly_ritual_time.dart';

abstract final class OraclyUniverseClock {
  OraclyUniverseClock._();

  /// Next existing boundary: 05:00, 12:00, 17:00, 21:00.
  static DateTime nextBoundary(DateTime now) {
    const hours = <int>[5, 12, 17, 21];
    for (final hour in hours) {
      final mark = DateTime(now.year, now.month, now.day, hour);
      if (mark.isAfter(now)) return mark;
    }
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 5);
  }

  static bool shouldRefresh({
    required OraclyRitualTime previous,
    required Duration previousOffset,
    required DateTime now,
  }) {
    return OraclyRitualAtmosphere.fromHour(now.hour) != previous ||
        now.timeZoneOffset != previousOffset;
  }
}
