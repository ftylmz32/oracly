/// EPIC-012 — Computed personal journey snapshot — memories, not statistics.
library;

import '../../../core/domain/models/personal_insight_report.dart';

/// A quiet summary of the user's path — never scored or gamified.
class PersonalJourneySnapshot {
  const PersonalJourneySnapshot({
    required this.totalReadings,
    required this.notesWritten,
    required this.favoritedMemories,
    required this.recurringCards,
    required this.insightReport,
    this.journeyBeginLabel,
    this.mostDrawnCard,
  });

  final int totalReadings;
  final int notesWritten;
  final int favoritedMemories;
  final int recurringCards;
  final PersonalInsightReport insightReport;
  final String? journeyBeginLabel;
  final String? mostDrawnCard;

  bool get hasMemories => totalReadings > 0;
}
