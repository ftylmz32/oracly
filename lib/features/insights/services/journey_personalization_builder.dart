/// EPIC-013 — Builds journey hints from saved readings only.
library;

import '../../../core/domain/models/reading.dart';
import '../../../core/history/history_scale_policy.dart';
import '../models/journey_personalization_hints.dart';
import 'personal_insight_engine.dart';

abstract final class JourneyPersonalizationBuilder {
  JourneyPersonalizationBuilder._();

  static JourneyPersonalizationHints fromHistory(
    List<ReadingModel> readings, {
    String? excludeSessionId,
    List<String> extraThemeLabels = const [],
  }) {
    final prior = readings
        .where(
          (r) =>
              excludeSessionId == null ||
              (r.id != excludeSessionId && r.sessionId != excludeSessionId),
        )
        .toList();

    final extras = extraThemeLabels
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (prior.isEmpty && extras.isEmpty) {
      return const JourneyPersonalizationHints();
    }

    if (prior.isEmpty) {
      return JourneyPersonalizationHints(recurringThemeLabels: extras);
    }

    final themeWindow = HistoryScalePolicy.newestByDate(
      prior,
      (r) => r.createdAt,
    );
    final report = PersonalInsightEngine.analyze(
      themeWindow,
      totalReadings: prior.length,
    );
    final themeLabels = [
      ...report.recurringThemes.map((e) => e.theme.label),
      ...extras.where(
        (label) => !report.recurringThemes.any((e) => e.theme.label == label),
      ),
    ];

    final recentCards = <String>[];
    for (final reading in prior.take(6)) {
      if (!recentCards.contains(reading.cardName)) {
        recentCards.add(reading.cardName);
      }
    }

    final hasNotes = prior.any(
      (r) => r.personalNote != null && r.personalNote!.trim().isNotEmpty,
    );

    final openings = <String>[];
    for (final reading in prior.take(4)) {
      final src = reading.summaryExcerpt ?? reading.aiSummary;
      final fp = JourneyPersonalizationHints.fingerprint(src);
      if (fp.length >= 24 && !openings.contains(fp)) openings.add(fp);
    }

    return JourneyPersonalizationHints(
      recurringThemeLabels: themeLabels,
      recentCardNames: recentCards.take(3).toList(growable: false),
      hasPriorNotes: hasNotes,
      priorReadingCount: prior.length,
      priorOpenings: openings,
    );
  }
}
