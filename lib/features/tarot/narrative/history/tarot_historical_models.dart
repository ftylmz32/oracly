/// Normalized historical Tarot FACT models (Phase 4A).
/// Storage-agnostic — adapters populate these in Phase 4C.
library;

import '../evidence/narrative_question_grounding.dart';

class TarotHistoricalCardOccurrence {
  const TarotHistoricalCardOccurrence({
    required this.canonicalCardId,
    required this.isReversed,
    this.orientationKnown = true,
    this.positionKey,
    this.positionIndex,
  });

  final String canonicalCardId;
  final bool isReversed;
  final bool orientationKnown;
  final String? positionKey;
  final int? positionIndex;
}

class TarotHistoricalReadingRecord {
  TarotHistoricalReadingRecord({
    required this.readingId,
    required this.occurredAt,
    required this.spreadId,
    required List<TarotHistoricalCardOccurrence> cards,
    this.sessionId,
    this.ownerId,
    this.questionKind,
    this.topicId,
    this.intentionSummary,
    this.interpretationSummary,
  }) : cards = List<TarotHistoricalCardOccurrence>.unmodifiable(cards);

  final String readingId;
  final String? sessionId;
  final String? ownerId;
  final DateTime occurredAt;
  final String spreadId;
  final QuestionKind? questionKind;
  final String? topicId;
  final String? intentionSummary;
  final List<TarotHistoricalCardOccurrence> cards;
  final String? interpretationSummary;
}

class TarotHistoricalSnapshot {
  TarotHistoricalSnapshot({
    required List<TarotHistoricalReadingRecord> tarotReadings,
  }) : tarotReadings = List<TarotHistoricalReadingRecord>.unmodifiable(
         tarotReadings,
       );

  final List<TarotHistoricalReadingRecord> tarotReadings;
}
