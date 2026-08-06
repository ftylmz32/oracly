/// RC-010 — Structured reflection output for future modules.
library;

import 'growth_insight.dart';
import 'journey_milestone.dart';
import 'personal_trend.dart';
import 'recurring_theme.dart';

class ReflectionSummary {
  const ReflectionSummary({
    required this.generatedAt,
    required this.schemaVersion,
    required this.recurringThemes,
    required this.growthInsights,
    required this.milestones,
    required this.trends,
  });

  static const int currentSchemaVersion = 1;

  final DateTime generatedAt;
  final int schemaVersion;
  final List<RecurringTheme> recurringThemes;
  final List<GrowthInsight> growthInsights;
  final List<JourneyMilestone> milestones;
  final List<PersonalTrend> trends;

  bool get hasObservablePatterns =>
      recurringThemes.isNotEmpty ||
      growthInsights.isNotEmpty ||
      milestones.isNotEmpty ||
      trends.isNotEmpty;
}
