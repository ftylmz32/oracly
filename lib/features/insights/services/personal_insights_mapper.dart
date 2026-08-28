/// SPRINT-004 — Maps reflection engine output to letter-style insights.
library;

import '../../../core/domain/models/personal_insight_report.dart';
import '../../../core/intelligence/domain/models/reflection_entry.dart';
import '../../../core/reflection/domain/models/growth_insight.dart';
import '../../../core/reflection/domain/models/journey_milestone.dart';
import '../../../core/reflection/domain/models/personal_trend.dart';
import '../../../core/reflection/domain/models/recurring_theme.dart';
import '../../../core/reflection/domain/models/reflection_evidence_kind.dart';
import '../../../core/reflection/domain/models/reflection_input.dart';
import '../../../core/reflection/domain/models/reflection_summary.dart'
    as core;
import '../copy/personal_insights_copy.dart';
import '../models/growth_snapshot.dart';
import '../models/insight.dart';
import '../models/insight_category.dart';
import '../models/insight_evidence.dart';
import '../models/personal_pattern.dart';
import '../models/reflection_summary.dart';

abstract final class PersonalInsightsMapper {
  PersonalInsightsMapper._();

  static InsightReflectionSummary compose({
    required core.ReflectionSummary reflection,
    required PersonalInsightReport tarotReport,
    required ReflectionInput input,
    required Set<String> excludedIds,
  }) {
    final generatedAt = reflection.generatedAt;
    final insights = <Insight>[
      ..._recurringThemes(reflection.recurringThemes, generatedAt),
      ..._symbolRecurrence(reflection.recurringThemes, generatedAt),
      ..._emotionalShifts(reflection.growthInsights, generatedAt),
      ..._meaningfulReflections(
        tarotReport: tarotReport,
        reflections: input.reflections,
        generatedAt: generatedAt,
      ),
      ..._milestones(reflection.milestones, generatedAt),
      ..._consistency(reflection.trends, generatedAt),
    ]..removeWhere((i) => excludedIds.contains(i.id));

    final patterns = _patterns(reflection.recurringThemes);
    final growth = _growthSnapshot(
      reflection: reflection,
      insights: insights,
      generatedAt: generatedAt,
    );

    return InsightReflectionSummary(
      salutation: PersonalInsightsCopy.salutation,
      closingNote: PersonalInsightsCopy.closingNote,
      generatedAt: generatedAt,
      insights: insights,
      growthSnapshot: growth,
      patterns: patterns,
    );
  }

  static List<Insight> _recurringThemes(
    List<RecurringTheme> themes,
    DateTime generatedAt,
  ) {
    return themes
        .where(
          (t) =>
              t.evidence != ReflectionEvidenceKind.cardDraw &&
              t.occurrenceCount >= 2,
        )
        .map(
          (theme) => Insight(
            id: 'insight_theme_${theme.id}',
            category: InsightCategory.recurringTheme,
            title: theme.label,
            body: _themeBody(theme),
            generatedAt: generatedAt,
            evidence: [
              InsightEvidence(
                source: _sourceForEvidence(theme.evidence),
                reference: theme.label,
                observedAt: theme.lastObserved,
              ),
            ],
          ),
        )
        .toList();
  }

  static List<Insight> _symbolRecurrence(
    List<RecurringTheme> themes,
    DateTime generatedAt,
  ) {
    return themes
        .where(
          (t) =>
              t.evidence == ReflectionEvidenceKind.cardDraw &&
              t.occurrenceCount >= 2,
        )
        .map(
          (theme) => Insight(
            id: 'insight_symbol_${theme.id}',
            category: InsightCategory.symbolRecurrence,
            title: theme.label,
            body: '${theme.label} kartı açılımlarında tekrar eden '
                'bir sembol olarak belirdi — kendi dilinde '
                'sana bir şey anlatıyor olabilir.',
            generatedAt: generatedAt,
            evidence: [
              InsightEvidence(
                source: InsightEvidenceSource.tarot,
                reference: theme.label,
                observedAt: theme.lastObserved,
              ),
            ],
          ),
        )
        .toList();
  }

  static List<Insight> _emotionalShifts(
    List<GrowthInsight> growth,
    DateTime generatedAt,
  ) {
    return growth
        .where(
          (g) =>
              g.kind == GrowthInsightKind.shiftingFocus ||
              g.kind == GrowthInsightKind.deepeningTheme,
        )
        .map(
          (item) => Insight(
            id: 'insight_growth_${item.id}',
            category: InsightCategory.emotionalShift,
            title: _growthTitle(item.kind),
            body: item.observation,
            generatedAt: generatedAt,
          ),
        )
        .toList();
  }

  static List<Insight> _meaningfulReflections({
    required PersonalInsightReport tarotReport,
    required List<ReflectionEntry> reflections,
    required DateTime generatedAt,
  }) {
    final insights = <Insight>[];

    final monthly = tarotReport.monthlyReflection;
    if (monthly != null) {
      insights.add(
        Insight(
          id: 'insight_monthly_${monthly.monthLabel}',
          category: InsightCategory.meaningfulReflection,
          title: monthly.monthLabel,
          body: monthly.observation,
          generatedAt: generatedAt,
          evidence: [
            InsightEvidence(
              source: InsightEvidenceSource.tarot,
              reference: monthly.monthLabel,
            ),
          ],
        ),
      );
    }

    final saved = [...reflections]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    for (final entry in saved.where((r) => r.text.trim().length >= 24).take(2)) {
      insights.add(
        Insight(
          id: 'insight_reflection_${entry.id}',
          category: InsightCategory.meaningfulReflection,
          title: _reflectionTitle(entry),
          body: _truncateReflection(entry.text),
          generatedAt: generatedAt,
          evidence: [
            InsightEvidence(
              source: _sourceForJourney(entry.source),
              reference: entry.id,
              observedAt: entry.recordedAt,
            ),
          ],
        ),
      );
    }

    return insights;
  }

  static List<Insight> _milestones(
    List<JourneyMilestone> milestones,
    DateTime generatedAt,
  ) {
    return milestones.map(
      (m) => Insight(
        id: 'insight_milestone_${m.id}',
        category: InsightCategory.growthMilestone,
        title: m.label,
        body: m.detail ?? m.label,
        generatedAt: generatedAt,
        evidence: [
          InsightEvidence(
            source: InsightEvidenceSource.savedReflection,
            reference: m.id,
            observedAt: m.reachedAt,
          ),
        ],
      ),
    ).toList();
  }

  static List<Insight> _consistency(
    List<PersonalTrend> trends,
    DateTime generatedAt,
  ) {
    return trends
        .where((t) => t.kind == PersonalTrendKind.reflectionCadence)
        .map(
          (trend) => Insight(
            id: 'insight_cadence_${trend.id}',
            category: InsightCategory.reflectionConsistency,
            title: 'Yansıma ritmi',
            body: _cadenceBody(trend),
            generatedAt: generatedAt,
          ),
        )
        .toList();
  }

  static List<PersonalPattern> _patterns(List<RecurringTheme> themes) {
    return themes
        .where((t) => t.occurrenceCount >= 2)
        .map(
          (theme) => PersonalPattern(
            id: 'pattern_${theme.id}',
            label: theme.label,
            observation: _patternObservation(theme),
            occurrenceCount: theme.occurrenceCount,
            primarySource: _sourceForEvidence(theme.evidence),
          ),
        )
        .toList();
  }

  static GrowthSnapshot? _growthSnapshot({
    required core.ReflectionSummary reflection,
    required List<Insight> insights,
    required DateTime generatedAt,
  }) {
    final growthInsights = reflection.growthInsights;
    final milestones = reflection.milestones;
    if (growthInsights.isEmpty && milestones.isEmpty) return null;

    final parts = <String>[];
    if (growthInsights.isNotEmpty) {
      parts.add(growthInsights.first.observation);
    }
    if (milestones.length >= 2) {
      parts.add(
        'Kayıtlarında birkaç anlamlı dönüm noktası '
        'gözlemlenebiliyor — yolculuğun sessizce büyüyor olabilir.',
      );
    } else if (milestones.isNotEmpty) {
      parts.add(milestones.last.label);
    }

    final highlights = insights
        .where(
          (i) =>
              i.category == InsightCategory.growthMilestone ||
              i.category == InsightCategory.emotionalShift,
        )
        .take(3)
        .toList();

    return GrowthSnapshot(
      narrative: parts.join(' '),
      asOf: generatedAt,
      highlights: highlights,
    );
  }

  static String _themeBody(RecurringTheme theme) {
    if (theme.evidence == ReflectionEvidenceKind.journalTopic) {
      return 'Kişisel notlarında ${theme.label.toLowerCase()} '
          'teması tekrar ediyor — kendi sesinin bu konuda '
          'nazikçe kalıyor olabileceğini fark edebilirsin.';
    }
    return 'Açılımlarında ${theme.label.toLowerCase()} teması '
        'tekrar ediyor — senin izinin gözlemlenebilir bir ritmi.';
  }

  static String _patternObservation(RecurringTheme theme) {
    if (theme.evidence == ReflectionEvidenceKind.cardDraw) {
      return '${theme.label} kartı açılımlarında tekrar eden '
          'bir sembol olarak belirdi.';
    }
    return '${theme.label} teması keşiflerinde tekrar eden '
        'bir iz olarak görünüyor.';
  }

  static String _cadenceBody(PersonalTrend trend) => switch (trend.direction) {
        TrendDirection.rising =>
          'Son dönemde kişisel yansımaların daha sık görünüyor — '
              'kendi sesinle buluşma ritmin güçleniyor olabilir.',
        TrendDirection.steady =>
          'Yansımaların düzenli bir ritimde devam ediyor — '
              'sakin bir süreklilik hissediliyor.',
        TrendDirection.fading =>
          'Son dönemde yansımaların biraz seyrekleşti — '
              'bu da bir dönemin doğal sonu olabilir.',
      };

  static String _growthTitle(GrowthInsightKind kind) => switch (kind) {
        GrowthInsightKind.shiftingFocus => 'Yeni bir odak',
        GrowthInsightKind.deepeningTheme => 'Derinleşen tema',
        GrowthInsightKind.newEngagement => 'Artan yansıma',
      };

  static String _reflectionTitle(ReflectionEntry entry) => switch (entry.source) {
        JourneyReflectionSource.dream => 'Rüyadan bir yansıma',
        JourneyReflectionSource.astrology => 'Haritandan bir not',
        JourneyReflectionSource.conversation => 'Sohbetten bir iz',
        JourneyReflectionSource.ritual => 'Ritüelden bir an',
        JourneyReflectionSource.reading => 'Açılımdan bir not',
      };

  static String _truncateReflection(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 180) return trimmed;
    return '${trimmed.substring(0, 177)}…';
  }

  static InsightEvidenceSource _sourceForEvidence(ReflectionEvidenceKind kind) {
    return switch (kind) {
      ReflectionEvidenceKind.cardDraw => InsightEvidenceSource.tarot,
      ReflectionEvidenceKind.journalTopic => InsightEvidenceSource.journal,
      ReflectionEvidenceKind.themeTag => InsightEvidenceSource.tarot,
      ReflectionEvidenceKind.keyword => InsightEvidenceSource.savedReflection,
      ReflectionEvidenceKind.spreadUsage => InsightEvidenceSource.tarot,
      ReflectionEvidenceKind.engagement => InsightEvidenceSource.savedReflection,
    };
  }

  static InsightEvidenceSource _sourceForJourney(JourneyReflectionSource source) {
    return switch (source) {
      JourneyReflectionSource.dream => InsightEvidenceSource.dream,
      JourneyReflectionSource.astrology => InsightEvidenceSource.birthChart,
      JourneyReflectionSource.conversation => InsightEvidenceSource.companion,
      JourneyReflectionSource.reading => InsightEvidenceSource.journal,
      JourneyReflectionSource.ritual => InsightEvidenceSource.savedReflection,
    };
  }
}
