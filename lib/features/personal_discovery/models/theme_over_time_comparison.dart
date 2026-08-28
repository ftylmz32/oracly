/// Earlier vs recent theme windows backed by stored observations.
library;

import 'theme_over_time_period.dart';

class ThemeOverTimeWindow {
  const ThemeOverTimeWindow({
    required this.theme,
    required this.sightingCount,
    required this.sources,
  });

  final String theme;
  final int sightingCount;
  final List<String> sources;
}

class ThemeOverTimeComparison {
  const ThemeOverTimeComparison({
    required this.period,
    required this.earlier,
    required this.recent,
    required this.themesDiffer,
  });

  final ThemeOverTimePeriod period;
  final ThemeOverTimeWindow earlier;
  final ThemeOverTimeWindow recent;
  final bool themesDiffer;
}
