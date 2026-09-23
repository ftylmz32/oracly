/// Recurrence evidence shells — Phase 3 empty; Phase 4A fills card recurrence.
library;

class RecurringOccurrence {
  const RecurringOccurrence({
    required this.readingId,
    required this.at,
    required this.spreadId,
    required this.positionKey,
    required this.isReversed,
    this.orientationKnown = true,
    this.intentionSummary,
  });

  final String readingId;
  final DateTime at;
  final String spreadId;
  final String positionKey;
  final bool isReversed;

  /// When false, [isReversed] is an inert sentinel and must not authorize
  /// upright/reversed historical claims.
  final bool orientationKnown;
  final String? intentionSummary;
}

class TarotRecurringCardEvidence {
  const TarotRecurringCardEvidence({
    required this.evidenceId,
    required this.canonicalCardId,
    required this.occurrenceCount,
    required this.occurrences,
    required this.contextsOverlap,
    this.overlapSummaryKey,
  });

  final String evidenceId;
  final String canonicalCardId;
  final int occurrenceCount;
  final List<RecurringOccurrence> occurrences;
  final bool contextsOverlap;
  final String? overlapSummaryKey;
}

class TarotRecurringThemeEvidence {
  const TarotRecurringThemeEvidence({
    required this.evidenceId,
    required this.themeIdOrLabel,
    required this.supportCount,
    required this.supportingReadingIds,
    required this.relatedCardIds,
    required this.relevanceToCurrentAsk,
  });

  final String evidenceId;
  final String themeIdOrLabel;
  final int supportCount;
  final List<String> supportingReadingIds;
  final List<String> relatedCardIds;
  final double relevanceToCurrentAsk;
}
