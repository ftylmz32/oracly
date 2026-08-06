/// RC-010 — Detects observable emotional focus shifts between periods.
library;

import '../../../domain/models/personal_insight_theme.dart';
import '../../../domain/models/reading.dart';
import '../../../../features/insights/services/personal_insight_engine.dart';
import '../../domain/models/growth_insight.dart';
import '../../domain/models/reflection_input.dart';
import '../reflection_engine_thresholds.dart';

abstract final class EmotionalFocusAnalyzer {
  EmotionalFocusAnalyzer._();

  static List<GrowthInsight> analyze(ReflectionInput input) {
    if (input.readings.length < ReflectionEngineThresholds.minReadingsForThemes) {
      return const [];
    }

    final recentCutoff = input.asOf.subtract(
      const Duration(days: ReflectionEngineThresholds.recentPeriodDays),
    );
    final priorCutoff = recentCutoff.subtract(
      const Duration(days: ReflectionEngineThresholds.priorPeriodDays),
    );

    final recent = input.readings
        .where((r) => !r.createdAt.isBefore(recentCutoff))
        .toList();
    final prior = input.readings
        .where(
          (r) =>
              !r.createdAt.isBefore(priorCutoff) &&
              r.createdAt.isBefore(recentCutoff),
        )
        .toList();

    if (recent.length < 2) return const [];

    final recentCounts = _themeCounts(recent);
    final priorCounts = _themeCounts(prior);
    final insights = <GrowthInsight>[];

    for (final theme in PersonalInsightTheme.values) {
      final recentCount = recentCounts[theme] ?? 0;
      final priorCount = priorCounts[theme] ?? 0;

      if (recentCount >= ReflectionEngineThresholds.minThemeOccurrences &&
          priorCount == 0) {
        insights.add(
          GrowthInsight(
            id: 'growth_shift_${theme.id}',
            kind: GrowthInsightKind.shiftingFocus,
            observation: 'Son dönemde okumaların sık sık '
                '${theme.label.toLowerCase()} temasına değindi — '
                'bu odak daha önce belirgin değildi.',
            observedAt: input.asOf,
            evidenceRefs: recent.map((r) => r.id).take(3).toList(),
          ),
        );
        continue;
      }

      if (recentCount >= priorCount + 2 &&
          recentCount >= ReflectionEngineThresholds.minThemeOccurrences) {
        insights.add(
          GrowthInsight(
            id: 'growth_deepen_${theme.id}',
            kind: GrowthInsightKind.deepeningTheme,
            observation: '${theme.label} teması son dönemde '
                'daha sık yankılandı — bir derinleşme hissediliyor olabilir.',
            observedAt: input.asOf,
            evidenceRefs: recent.map((r) => r.id).take(3).toList(),
          ),
        );
      }
    }

    if (input.reflections
            .where((r) => !r.recordedAt.isBefore(recentCutoff))
            .length >=
        ReflectionEngineThresholds.minJournalTopicOccurrences &&
        input.reflections
                .where(
                  (r) =>
                      !r.recordedAt.isBefore(priorCutoff) &&
                      r.recordedAt.isBefore(recentCutoff),
                )
                .length <
            ReflectionEngineThresholds.minJournalTopicOccurrences) {
      insights.add(
        GrowthInsight(
          id: 'growth_reflection_engagement',
          kind: GrowthInsightKind.newEngagement,
          observation: 'Son dönemde kişisel yansımaların arttı — '
              'kendi sesinle daha sık buluşuyor olabilirsin.',
          observedAt: input.asOf,
        ),
      );
    }

    return insights;
  }

  static Map<PersonalInsightTheme, int> _themeCounts(List<ReadingModel> readings) {
    final counts = <PersonalInsightTheme, int>{};
    for (final reading in readings) {
      final tags = PersonalInsightEngine.tagsForReading(
        aiSummary: reading.aiSummary,
        cardName: reading.cardName,
        intention: reading.intention,
      );
      for (final tag in tags) {
        final theme = PersonalInsightEngine.fromStorageTag(tag);
        if (theme == null) continue;
        counts[theme] = (counts[theme] ?? 0) + 1;
      }
    }
    return counts;
  }
}
