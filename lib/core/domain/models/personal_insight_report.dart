/// OR-439 — Computed insight snapshot — local, observational only.
library;

import 'personal_insight_theme.dart';

/// One theme that appeared across multiple readings.
class PersonalThemeEcho {
  const PersonalThemeEcho({
    required this.theme,
    required this.count,
  });

  final PersonalInsightTheme theme;
  final int count;
}

/// Gentle monthly observation — never predictive.
class PersonalMonthlyReflection {
  const PersonalMonthlyReflection({
    required this.monthLabel,
    required this.observation,
    required this.recurringThemes,
    required this.readingCount,
  });

  final String monthLabel;
  final String observation;
  final List<PersonalInsightTheme> recurringThemes;
  final int readingCount;
}

/// Aggregated personal insight from journal history.
class PersonalInsightReport {
  const PersonalInsightReport({
    required this.recurringThemes,
    this.monthlyReflection,
    required this.totalReadings,
  });

  final List<PersonalThemeEcho> recurringThemes;
  final PersonalMonthlyReflection? monthlyReflection;
  final int totalReadings;

  bool get hasThemePattern => recurringThemes.isNotEmpty;
  bool get hasMonthlyReflection => monthlyReflection != null;
}
