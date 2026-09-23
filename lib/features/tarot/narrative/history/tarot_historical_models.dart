/// Normalized historical Tarot FACT + connected-memory snapshot (Phase 4A/4B).
library;

import '../evidence/narrative_question_grounding.dart';
import 'tarot_connected_memory_models.dart';

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
    List<TarotConnectedMemoryRecord> connectedMemories = const [],
  }) : tarotReadings = List<TarotHistoricalReadingRecord>.unmodifiable(
         tarotReadings,
       ),
       connectedMemories = List<TarotConnectedMemoryRecord>.unmodifiable(
         connectedMemories,
       );

  final List<TarotHistoricalReadingRecord> tarotReadings;
  final List<TarotConnectedMemoryRecord> connectedMemories;
}
