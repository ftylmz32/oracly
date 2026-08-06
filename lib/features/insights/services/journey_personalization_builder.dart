/// EPIC-013 — Builds journey hints from saved readings only.
library;

import '../../../core/domain/models/reading.dart';
import '../models/journey_personalization_hints.dart';
import 'personal_insight_engine.dart';

abstract final class JourneyPersonalizationBuilder {
  JourneyPersonalizationBuilder._();

  static JourneyPersonalizationHints fromHistory(
    List<ReadingModel> readings, {
    String? excludeSessionId,
  }) {
    final prior = readings
        .where(
          (r) =>
              excludeSessionId == null ||
              (r.id != excludeSessionId && r.sessionId != excludeSessionId),
        )
        .toList();

    if (prior.isEmpty) return const JourneyPersonalizationHints();

    final report = PersonalInsightEngine.analyze(prior);
    final themeLabels = report.recurringThemes
        .map((e) => e.theme.label)
        .toList(growable: false);

    final recentCards = <String>[];
    for (final reading in prior.take(6)) {
      if (!recentCards.contains(reading.cardName)) {
        recentCards.add(reading.cardName);
      }
    }

    final hasNotes = prior.any(
      (r) => r.personalNote != null && r.personalNote!.trim().isNotEmpty,
    );

    return JourneyPersonalizationHints(
      recurringThemeLabels: themeLabels,
      recentCardNames: recentCards.take(3).toList(growable: false),
      hasPriorNotes: hasNotes,
      priorReadingCount: prior.length,
    );
  }
}
