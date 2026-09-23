/// ReadingModel-only legacy → normalized Tarot historical row (Phase 4C).
library;

import '../../../../core/domain/models/reading.dart';
import '../../deck/oracly_tarot_bridge.dart';
import '../../reading/reading_question.dart';
import '../evidence/narrative_question_grounding.dart';
import '../evidence/narrative_spread_semantics.dart';
import 'tarot_history_card_normalize.dart';
import 'tarot_history_normalize_diagnostics.dart';
import 'tarot_historical_models.dart';
import 'tarot_historical_text.dart';

abstract final class TarotHistoryLegacyNormalize {
  TarotHistoryLegacyNormalize._();

  static ({
    TarotHistoricalReadingRecord? record,
    TarotHistoryNormalizeDiagnostics diag,
  })
  normalize({required ReadingModel reading, required String? currentOwnerId}) {
    if (reading.id.trim().isEmpty) {
      return (
        record: null,
        diag: const TarotHistoryNormalizeDiagnostics(skippedMalformed: 1),
      );
    }

    final spread = TarotHistoryCardNormalize.classicalFromTitle(
      reading.spreadType,
    );
    if (spread == null) {
      return (
        record: null,
        diag: const TarotHistoryNormalizeDiagnostics(skippedMalformed: 1),
      );
    }

    if (!_ownerAllowed(currentOwnerId, reading.userId)) {
      return (
        record: null,
        diag: const TarotHistoryNormalizeDiagnostics(skippedOwnerMismatch: 1),
      );
    }

    final cards = _cards(reading, spread);
    if (cards.isEmpty) {
      return (
        record: null,
        diag: const TarotHistoryNormalizeDiagnostics(skippedMalformed: 1),
      );
    }

    final grounded = NarrativeQuestionGrounding.from(
      rawQuestion: reading.intention,
      topic: reading.readingType,
    );
    final topic = reading.readingType?.trim();
    return (
      record: TarotHistoricalReadingRecord(
        readingId: reading.id,
        sessionId: reading.sessionId,
        ownerId: reading.userId,
        occurredAt: reading.createdAt.toUtc(),
        spreadId: spread.spreadId,
        questionKind: grounded.kind,
        topicId: (topic == null || topic.isEmpty) ? null : topic,
        intentionSummary: TarotHistoricalText.sanitizeIntention(
          ReadingQuestion.real(reading.intention),
        ),
        interpretationSummary: TarotHistoryCardNormalize.boundInterpretation(
          reading.aiSummary,
        ),
        cards: cards,
      ),
      diag: const TarotHistoryNormalizeDiagnostics(),
    );
  }

  static List<TarotHistoricalCardOccurrence> _cards(
    ReadingModel reading,
    SpreadSemanticDefinition spread,
  ) {
    if (reading.cards.isNotEmpty) {
      final out = <TarotHistoricalCardOccurrence>[];
      for (final snap in reading.cards) {
        final bridged = OraclyTarotBridge.byRitualId(snap.cardId);
        if (bridged == null) continue;
        final idx = TarotHistoryCardNormalize.validIndex(
          spread,
          snap.positionIndex,
        );
        out.add(
          TarotHistoricalCardOccurrence(
            canonicalCardId: bridged.id,
            isReversed: snap.isReversed,
            orientationKnown: false,
            positionIndex: idx,
            positionKey: TarotHistoryCardNormalize.resolvePositionKey(
              spread: spread,
              positionIndex: idx,
            ),
          ),
        );
      }
      return out;
    }

    final bridged = OraclyTarotBridge.byRitualId(reading.cardId);
    if (bridged == null) return const [];
    final idx = TarotHistoryCardNormalize.validIndex(spread, reading.cardIndex);
    return [
      TarotHistoricalCardOccurrence(
        canonicalCardId: bridged.id,
        isReversed: false,
        orientationKnown: false,
        positionIndex: idx,
        positionKey: TarotHistoryCardNormalize.resolvePositionKey(
          spread: spread,
          positionIndex: idx,
        ),
      ),
    ];
  }

  static bool _ownerAllowed(String? currentOwnerId, String? rowOwner) {
    if (currentOwnerId != null) {
      return rowOwner != null && rowOwner == currentOwnerId;
    }
    return rowOwner == null;
  }
}
