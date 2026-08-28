/// One theme's observable span — never a fabricated arc.
library;

class OracleThemeHistoryEntry {
  const OracleThemeHistoryEntry({
    required this.theme,
    required this.sourceFeatures,
    required this.occurrenceCount,
    required this.firstObserved,
    required this.lastObserved,
  });

  final String theme;
  final List<String> sourceFeatures;
  final int occurrenceCount;
  final DateTime firstObserved;
  final DateTime lastObserved;

  bool get isCrossFeature => sourceFeatures.length >= 2;
}
