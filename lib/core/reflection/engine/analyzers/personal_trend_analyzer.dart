/// RC-010 — Detects trends across recent and prior observation windows.
library;

import '../../../domain/models/personal_insight_theme.dart';
import '../../../domain/models/reading.dart';
import '../../../../features/insights/services/personal_insight_engine.dart';
import '../../domain/models/personal_trend.dart';
import '../../domain/models/reflection_input.dart';
import '../reflection_engine_thresholds.dart';

abstract final class PersonalTrendAnalyzer {
  PersonalTrendAnalyzer._();

  static const _recentLabel = 'Son 45 gün';
  static const _priorLabel = 'Önceki 45 gün';

  static List<PersonalTrend> analyze(ReflectionInput input) {
    if (input.readings.isEmpty) return const [];

    final recentCutoff = input.asOf.subtract(
      const Duration(days: ReflectionEngineThresholds.recentPeriodDays),
    );
    final priorCutoff = recentCutoff.subtract(
      const Duration(days: ReflectionEngineThresholds.priorPeriodDays),
    );

    final recentReadings = input.readings
        .where((r) => !r.createdAt.isBefore(recentCutoff))
        .toList();
    final priorReadings = input.readings
        .where(
          (r) =>
              !r.createdAt.isBefore(priorCutoff) &&
              r.createdAt.isBefore(recentCutoff),
        )
        .toList();

    final trends = <PersonalTrend>[
      ..._themeTrends(recentReadings, priorReadings),
      ..._cardTrends(recentReadings, priorReadings),
      ..._spreadTrends(recentReadings, priorReadings),
      ..._reflectionCadenceTrend(input, recentCutoff, priorCutoff),
    ];

    return trends;
  }

  static List<PersonalTrend> _themeTrends(
    List<ReadingModel> recent,
    List<ReadingModel> prior,
  ) {
    final trends = <PersonalTrend>[];
    for (final theme in PersonalInsightTheme.values) {
      final recentCount = _countTheme(recent, theme);
      final priorCount = _countTheme(prior, theme);
      final direction = _direction(recentCount, priorCount);
      if (direction == null) continue;
      if (recentCount == 0 && priorCount == 0) continue;

      trends.add(
        PersonalTrend(
          id: 'trend_theme_${theme.id}',
          kind: PersonalTrendKind.themeFocus,
          subject: theme.label,
          direction: direction,
          recentPeriodCount: recentCount,
          priorPeriodCount: priorCount,
          recentPeriodLabel: _recentLabel,
          priorPeriodLabel: _priorLabel,
        ),
      );
    }
    return trends;
  }

  static List<PersonalTrend> _cardTrends(
    List<ReadingModel> recent,
    List<ReadingModel> prior,
  ) {
    final names = <String>{
      ...recent.map((r) => r.cardName),
      ...prior.map((r) => r.cardName),
    };
    final trends = <PersonalTrend>[];

    for (final name in names) {
      final recentCount = recent.where((r) => r.cardName == name).length;
      final priorCount = prior.where((r) => r.cardName == name).length;
      if (recentCount + priorCount < ReflectionEngineThresholds.minCardRecurrence) {
        continue;
      }
      final direction = _direction(recentCount, priorCount);
      if (direction == null) continue;

      trends.add(
        PersonalTrend(
          id: 'trend_card_${name.toLowerCase()}',
          kind: PersonalTrendKind.cardRecurrence,
          subject: name,
          direction: direction,
          recentPeriodCount: recentCount,
          priorPeriodCount: priorCount,
          recentPeriodLabel: _recentLabel,
          priorPeriodLabel: _priorLabel,
        ),
      );
    }
    return trends;
  }

  static List<PersonalTrend> _spreadTrends(
    List<ReadingModel> recent,
    List<ReadingModel> prior,
  ) {
    final spreads = <String>{
      ...recent.map((r) => r.spreadType),
      ...prior.map((r) => r.spreadType),
    };
    final trends = <PersonalTrend>[];

    for (final spread in spreads) {
      final recentCount = recent.where((r) => r.spreadType == spread).length;
      final priorCount = prior.where((r) => r.spreadType == spread).length;
      if (recentCount < ReflectionEngineThresholds.minSpreadPreference &&
          priorCount < ReflectionEngineThresholds.minSpreadPreference) {
        continue;
      }
      final direction = _direction(recentCount, priorCount);
      if (direction == null) continue;

      trends.add(
        PersonalTrend(
          id: 'trend_spread_${spread.toLowerCase()}',
          kind: PersonalTrendKind.spreadPreference,
          subject: spread,
          direction: direction,
          recentPeriodCount: recentCount,
          priorPeriodCount: priorCount,
          recentPeriodLabel: _recentLabel,
          priorPeriodLabel: _priorLabel,
        ),
      );
    }
    return trends;
  }

  static List<PersonalTrend> _reflectionCadenceTrend(
    ReflectionInput input,
    DateTime recentCutoff,
    DateTime priorCutoff,
  ) {
    final recentCount = input.reflections
        .where((r) => !r.recordedAt.isBefore(recentCutoff))
        .length;
    final priorCount = input.reflections
        .where(
          (r) =>
              !r.recordedAt.isBefore(priorCutoff) &&
              r.recordedAt.isBefore(recentCutoff),
        )
        .length;

    if (recentCount == 0 && priorCount == 0) return const [];

    final direction = _direction(recentCount, priorCount);
    if (direction == null) return const [];

    return [
      PersonalTrend(
        id: 'trend_reflection_cadence',
        kind: PersonalTrendKind.reflectionCadence,
        subject: 'Kişisel yansımalar',
        direction: direction,
        recentPeriodCount: recentCount,
        priorPeriodCount: priorCount,
        recentPeriodLabel: _recentLabel,
        priorPeriodLabel: _priorLabel,
      ),
    ];
  }

  static int _countTheme(List<ReadingModel> readings, PersonalInsightTheme theme) {
    var count = 0;
    for (final reading in readings) {
      final tags = PersonalInsightEngine.tagsForReading(
        aiSummary: reading.aiSummary,
        cardName: reading.cardName,
        intention: reading.intention,
      );
      if (tags.contains(theme.storageTag)) count++;
    }
    return count;
  }

  static TrendDirection? _direction(int recent, int prior) {
    if (recent == prior) {
      if (recent == 0) return null;
      return TrendDirection.steady;
    }
    if (recent > prior && recent >= ReflectionEngineThresholds.minThemeOccurrences) {
      return TrendDirection.rising;
    }
    if (prior > recent && prior >= ReflectionEngineThresholds.minThemeOccurrences) {
      return TrendDirection.fading;
    }
    return null;
  }
}
