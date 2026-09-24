/// Phase 6F — production-safe session → live Narrative card input mapping.
library;

import '../../deck/oracly_tarot_bridge.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/spread_engine.dart';
import '../../signature_spreads/signature_spread_shadow_input.dart';

enum NarrativeTarotLiveInputFailure {
  emptySessionId,
  emptyDrawnCards,
  cardCountMismatch,
  outOfRangePosition,
  duplicatePosition,
  missingPosition,
  invalidRitualCard,
  positionKeyMismatch,
}

/// Shared session structural guards + input mapping (shadow reuses this).
abstract final class NarrativeTarotLiveSession {
  NarrativeTarotLiveSession._();

  static NarrativeTarotLiveInputFailure? guard(ReadingSession session) {
    if (session.id.trim().isEmpty) {
      return NarrativeTarotLiveInputFailure.emptySessionId;
    }
    final drawn = session.drawnCards;
    if (drawn.isEmpty) {
      return NarrativeTarotLiveInputFailure.emptyDrawnCards;
    }
    if (drawn.length != session.spread.cardCount) {
      return NarrativeTarotLiveInputFailure.cardCountMismatch;
    }
    final byIndex = <int, TarotDrawnCard>{};
    for (final d in drawn) {
      if (d.positionIndex < 0 || d.positionIndex >= session.spread.cardCount) {
        return NarrativeTarotLiveInputFailure.outOfRangePosition;
      }
      if (byIndex.containsKey(d.positionIndex)) {
        return NarrativeTarotLiveInputFailure.duplicatePosition;
      }
      byIndex[d.positionIndex] = d;
      if (OraclyTarotBridge.byRitualId(d.card.id) == null) {
        return NarrativeTarotLiveInputFailure.invalidRitualCard;
      }
      final expected = SpreadEngine.positionAt(
        session.spread,
        d.positionIndex,
      )?.key;
      final stored = d.positionKey?.trim() ?? '';
      if (stored.isNotEmpty && expected != null && stored != expected) {
        return NarrativeTarotLiveInputFailure.positionKeyMismatch;
      }
    }
    for (var i = 0; i < session.spread.cardCount; i++) {
      if (!byIndex.containsKey(i)) {
        return NarrativeTarotLiveInputFailure.missingPosition;
      }
    }
    return null;
  }

  /// Live Narrative input — never copies ReadingContext fields.
  static SignatureSpreadShadowInput toLiveInput({
    required ReadingSession session,
    required String readingId,
    required String languageCode,
  }) {
    return SignatureSpreadShadowInput(
      sessionId: session.id,
      readingId: readingId,
      languageCode: languageCode,
      spreadType: session.spread,
      questionRaw: session.intention.text,
      intentionTopic: session.intention.topic,
      cards: [
        for (final d in session.drawnCards)
          SignatureSpreadShadowCard(
            ritualCardId: d.card.id,
            isReversed: d.isReversed,
            positionIndex: d.positionIndex,
            positionKey: d.positionKey,
          ),
      ],
    );
  }
}
