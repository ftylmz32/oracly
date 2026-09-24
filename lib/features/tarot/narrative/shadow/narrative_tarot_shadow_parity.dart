/// Phase 6E — machine-testable legacy ↔ Narrative shared-fact parity.
library;

import '../../deck/oracly_tarot_bridge.dart';
import '../../domain/models/tarot_spread.dart';
import '../../interpretation/models/reading_context.dart';
import '../evidence/narrative_request.dart';
import 'narrative_tarot_shadow_launch.dart';

/// Shared reading facts only — never prose / keywords / profile equality.
class NarrativeTarotShadowParityReport {
  const NarrativeTarotShadowParityReport({
    required this.sessionIdentity,
    required this.readingIdentity,
    required this.locale,
    required this.question,
    required this.topic,
    required this.spread,
    required this.cardCount,
    required this.ritualCardId,
    required this.canonicalCardId,
    required this.reversal,
    required this.positionIndex,
    required this.positionKey,
  });

  final bool sessionIdentity;
  final bool readingIdentity;
  final bool locale;
  final bool question;
  final bool topic;
  final bool spread;
  final bool cardCount;
  final bool ritualCardId;
  final bool canonicalCardId;
  final bool reversal;
  final bool positionIndex;
  final bool positionKey;

  bool get overallPass =>
      sessionIdentity &&
      readingIdentity &&
      locale &&
      question &&
      topic &&
      spread &&
      cardCount &&
      ritualCardId &&
      canonicalCardId &&
      reversal &&
      positionIndex &&
      positionKey;
}

abstract final class NarrativeTarotShadowParity {
  NarrativeTarotShadowParity._();

  static NarrativeTarotShadowParityReport compare({
    required ReadingContext legacy,
    required TarotNarrativeRequest narrative,
    required String readingId,
    required TarotSpreadType sessionSpread,
  }) {
    final nCards = narrative.cards;
    final lCards = legacy.cards;
    var ritual = lCards.length == nCards.length;
    var canonical = ritual;
    var reversal = ritual;
    var posIndex = ritual;
    var posKey = ritual;
    for (var i = 0; i < nCards.length && ritual; i++) {
      final l = lCards[i];
      final n = nCards[i];
      ritual = ritual && l.cardId == n.ritualCardId;
      canonical = canonical &&
          OraclyTarotBridge.byRitualId(l.cardId)?.id == n.canonicalCardId &&
          n.canonicalCardId == OraclyTarotBridge.byRitualId(n.ritualCardId)?.id;
      reversal = reversal && l.isReversed == n.isReversed;
      posIndex = posIndex && l.positionIndex == n.positionIndex;
      posKey = posKey && l.positionKey == n.positionKey;
    }
    final hasQ = (legacy.userQuestion ?? '').trim().isNotEmpty;
    return NarrativeTarotShadowParityReport(
      sessionIdentity: legacy.sessionId == narrative.sessionId,
      readingIdentity: readingId == narrative.readingId,
      locale: legacy.language == narrative.languageCode,
      question: legacy.userQuestion == narrative.question.rawText &&
          narrative.question.hasRealQuestion == hasQ,
      topic: legacy.readingTheme == narrative.question.topic,
      spread: NarrativeTarotShadowLaunch.isLiveLaunchCandidate(sessionSpread) &&
          NarrativeTarotShadowLaunch.narrativeSpreadId(sessionSpread) ==
              narrative.spread.spreadId &&
          legacy.spreadType == sessionSpread,
      cardCount: lCards.length == nCards.length &&
          nCards.length == narrative.spread.cardCount,
      ritualCardId: ritual,
      canonicalCardId: canonical,
      reversal: reversal,
      positionIndex: posIndex,
      positionKey: posKey,
    );
  }
}
