/// RC-010 — Shared observable thresholds for reflection analysis.
library;

abstract final class ReflectionEngineThresholds {
  ReflectionEngineThresholds._();

  static const int minReadingsForThemes = 3;
  static const int minThemeOccurrences = 2;
  static const int minCardRecurrence = 2;
  static const int minJournalTopicOccurrences = 2;
  static const int minSpreadPreference = 2;
  static const int recentPeriodDays = 45;
  static const int priorPeriodDays = 45;
}
