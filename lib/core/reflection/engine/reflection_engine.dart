/// RC-010 — Core reflection engine — pattern recognition, never prediction.
library;

import '../domain/models/reflection_input.dart';
import '../domain/models/reflection_summary.dart';
import 'analyzers/card_pattern_analyzer.dart';
import 'analyzers/emotional_focus_analyzer.dart';
import 'analyzers/milestone_analyzer.dart';
import 'analyzers/personal_trend_analyzer.dart';
import 'analyzers/recurring_theme_analyzer.dart';
import 'analyzers/reflection_topic_analyzer.dart';

/// Pure logic engine — UI-agnostic, AI-agnostic, storage-agnostic.
class ReflectionEngine {
  const ReflectionEngine();

  ReflectionSummary analyze(ReflectionInput input) {
    if (input.isEmpty) {
      return ReflectionSummary(
        generatedAt: input.asOf,
        schemaVersion: ReflectionSummary.currentSchemaVersion,
        recurringThemes: const [],
        growthInsights: const [],
        milestones: const [],
        trends: const [],
      );
    }

    final themePatterns = RecurringThemeAnalyzer.analyze(input);
    final cardPatterns = CardPatternAnalyzer.analyze(input);
    final topicPatterns = ReflectionTopicAnalyzer.analyze(input);

    return ReflectionSummary(
      generatedAt: input.asOf,
      schemaVersion: ReflectionSummary.currentSchemaVersion,
      recurringThemes: [
        ...themePatterns,
        ...cardPatterns,
        ...topicPatterns,
      ],
      growthInsights: EmotionalFocusAnalyzer.analyze(input),
      milestones: MilestoneAnalyzer.analyze(input),
      trends: PersonalTrendAnalyzer.analyze(input),
    );
  }
}
