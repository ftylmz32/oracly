/// Phase 6E — session → shadow input + basic input firewall (pure).
library;

import '../../deck/oracly_tarot_bridge.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/spread_engine.dart';
import '../../signature_spreads/signature_spread_shadow_input.dart';
import 'narrative_tarot_shadow_status.dart';

abstract final class NarrativeTarotShadowSession {
  NarrativeTarotShadowSession._();

  /// Fail-closed structural guards before safety / Phase 5.
  static NarrativeTarotShadowInputFailure? guard(ReadingSession session) {
    if (session.id.trim().isEmpty) {
      return NarrativeTarotShadowInputFailure.emptySessionId;
    }
    final drawn = session.drawnCards;
    if (drawn.isEmpty) {
      return NarrativeTarotShadowInputFailure.emptyDrawnCards;
    }
    if (drawn.length != session.spread.cardCount) {
      return NarrativeTarotShadowInputFailure.cardCountMismatch;
    }
    final byIndex = <int, TarotDrawnCard>{};
    for (final d in drawn) {
      if (d.positionIndex < 0 || d.positionIndex >= session.spread.cardCount) {
        return NarrativeTarotShadowInputFailure.outOfRangePosition;
      }
      if (byIndex.containsKey(d.positionIndex)) {
        return NarrativeTarotShadowInputFailure.duplicatePosition;
      }
      byIndex[d.positionIndex] = d;
      if (OraclyTarotBridge.byRitualId(d.card.id) == null) {
        return NarrativeTarotShadowInputFailure.invalidRitualCard;
      }
      final expected = SpreadEngine.positionAt(
        session.spread,
        d.positionIndex,
      )?.key;
      final stored = d.positionKey?.trim() ?? '';
      if (stored.isNotEmpty && expected != null && stored != expected) {
        return NarrativeTarotShadowInputFailure.positionKeyMismatch;
      }
    }
    for (var i = 0; i < session.spread.cardCount; i++) {
      if (!byIndex.containsKey(i)) {
        return NarrativeTarotShadowInputFailure.missingPosition;
      }
    }
    return null;
  }

  /// Independent Narrative shadow input — never copies ReadingContext fields.
  static SignatureSpreadShadowInput toShadowInput({
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
