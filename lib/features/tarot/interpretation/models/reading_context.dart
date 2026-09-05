/// OR-1180 — Runtime context for tarot interpretation.
library;

import 'package:flutter/foundation.dart';

import '../../../../features/insights/models/journey_personalization_hints.dart';
import '../../copy/tarot_l10n.dart';
import '../../deck/oracly_tarot_bridge.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/spread_engine.dart';
import '../../domain/models/tarot_spread.dart';
import '../../reading/reading_question.dart';
import '../../../../core/l10n/l10n.dart';

@immutable
class ReadingCardContext {
  const ReadingCardContext({
    required this.cardId,
    required this.cardName,
    required this.positionIndex,
    required this.positionLabel,
    required this.positionKey,
    required this.isReversed,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.keywords,
    this.element,
    this.imageAsset,
  });

  final int cardId;
  final String cardName;
  final int positionIndex;
  final String positionLabel;
  final String positionKey;
  final bool isReversed;
  final String uprightMeaning;
  final String reversedMeaning;
  final List<String> keywords;
  final String? element;
  final String? imageAsset;

  String get effectiveMeaning => isReversed ? reversedMeaning : uprightMeaning;
  String get orientationLabel =>
      TarotL10n.orientation(reversed: isReversed);
}

@immutable
class ReadingContext {
  const ReadingContext({
    required this.sessionId,
    required this.spreadType,
    required this.spreadLabel,
    required this.deckId,
    required this.language,
    required this.readingDate,
    required this.cards,
    this.userId,
    this.userQuestion,
    this.readingTheme,
    this.shuffleSeed,
    this.journeyHints,
  });

  final String sessionId;
  final TarotSpreadType spreadType;
  final String spreadLabel;
  final String deckId;
  final String language;
  final DateTime readingDate;
  final List<ReadingCardContext> cards;
  final String? userId;
  final String? userQuestion;
  final String? readingTheme;
  final int? shuffleSeed;
  final JourneyPersonalizationHints? journeyHints;

  ReadingContext withJourneyHints(JourneyPersonalizationHints hints) {
    return ReadingContext(
      sessionId: sessionId,
      spreadType: spreadType,
      spreadLabel: spreadLabel,
      deckId: deckId,
      language: language,
      readingDate: readingDate,
      cards: cards,
      userId: userId,
      userQuestion: userQuestion,
      readingTheme: readingTheme,
      shuffleSeed: shuffleSeed,
      journeyHints: hints,
    );
  }

  String get cacheKey {
    final q = (userQuestion ?? '').trim().hashCode;
    final continuity = journeyHints?.cacheToken ?? 'no-continuity';
    final lang = language.trim().toLowerCase();
    final theme = (readingTheme ?? '').trim().toLowerCase();
    final cardsKey =
        cards.map((c) => '${c.cardId}:${c.isReversed}').join('-');
    return 'interp_${sessionId}_${shuffleSeed ?? 0}_${q}_${lang}_${theme}_${continuity}_$cardsKey';
  }

  factory ReadingContext.fromSession(
    ReadingSession session, {
    String? language,
  }) {
    final code = language ?? OraclyL10n.code;
    return ReadingContext(
      sessionId: session.id,
      spreadType: session.spread,
      spreadLabel: TarotL10n.spread(session.spread),
      deckId: session.deckId,
      language: code,
      readingDate: session.completedAt ?? session.startedAt,
      userId: session.userId,
      userQuestion: ReadingQuestion.real(session.intention.text),
      readingTheme: session.intention.topic,
      shuffleSeed: session.shuffleSeed,
      cards: [
        for (final d in SpreadEngine.interpretationCards(
          spread: session.spread,
          drawn: session.drawnCards,
        ))
          ReadingCardContext(
            cardId: d.card.id,
            cardName: TarotL10n.cardName(
              d.card.id,
              fallback: d.card.name,
              language: code,
            ),
            positionIndex: d.positionIndex,
            positionLabel: _position(
              d,
              session.spread,
              code,
            ),
            positionKey: d.positionKey ??
                SpreadEngine.positionAt(session.spread, d.positionIndex)?.key ??
                'pos_${d.positionIndex}',
            isReversed: d.isReversed,
            uprightMeaning: _meaning(
              d.card.id,
              reversed: false,
              language: code,
              fallback: d.card.meaning,
            ),
            reversedMeaning: _meaning(
              d.card.id,
              reversed: true,
              language: code,
              fallback: d.card.reversedMeaning,
            ),
            keywords: _keys(
              d.card.id,
              language: code,
              fallback: d.card.keywords,
            ),
            element: d.card.element,
            imageAsset: d.card.image,
          ),
      ],
    );
  }
}

String _meaning(
  int id, {
  required bool reversed,
  required String language,
  required String fallback,
}) {
  final value = OraclyTarotBridge.meaning(
    id,
    reversed: reversed,
    language: language,
  );
  return value.trim().isEmpty ? fallback : value;
}

List<String> _keys(
  int id, {
  required String language,
  required List<String> fallback,
}) {
  final value = OraclyTarotBridge.keywords(id, language: language);
  return value.isEmpty ? fallback : value;
}

String _position(TarotDrawnCard drawn, TarotSpreadType spread, String code) {
  final key = drawn.positionKey ??
      SpreadEngine.positionAt(spread, drawn.positionIndex)?.key;
  if (key == null) {
    return OraclyL10n.t('tarot.card_field', languageCode: code);
  }
  final value = OraclyL10n.t('tarot.pos.$key', languageCode: code);
  return value == 'tarot.pos.$key' ? drawn.localizedPosition : value;
}
