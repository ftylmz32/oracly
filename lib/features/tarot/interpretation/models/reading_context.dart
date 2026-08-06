/// OR-1180 — Runtime context for tarot interpretation.
library;

import 'package:flutter/foundation.dart';

import '../../../../features/insights/models/journey_personalization_hints.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/tarot_spread.dart';

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
  String get orientationLabel => isReversed ? 'Ters' : 'Düz';
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

  String get cacheKey =>
      'interp_${sessionId}_${shuffleSeed ?? 0}_${cards.map((c) => "${c.cardId}:${c.isReversed}").join("-")}';

  factory ReadingContext.fromSession(
    ReadingSession session, {
    String language = 'tr',
  }) {
    return ReadingContext(
      sessionId: session.id,
      spreadType: session.spread,
      spreadLabel: session.spread.label,
      deckId: session.deckId,
      language: language,
      readingDate: session.completedAt ?? session.startedAt,
      userId: session.userId,
      userQuestion: session.intention.text.trim().isEmpty
          ? null
          : session.intention.text.trim(),
      readingTheme: session.intention.topic,
      shuffleSeed: session.shuffleSeed,
      cards: session.drawnCards
          .map(
            (d) => ReadingCardContext(
              cardId: d.card.id,
              cardName: d.card.name,
              positionIndex: d.positionIndex,
              positionLabel: d.positionLabel ?? 'Kart ${d.positionIndex + 1}',
              positionKey: d.positionKey ?? 'pos_${d.positionIndex}',
              isReversed: d.isReversed,
              uprightMeaning: d.card.meaning,
              reversedMeaning: d.card.reversedMeaning,
              keywords: d.card.keywords,
              element: d.card.element,
              imageAsset: d.card.image,
            ),
          )
          .toList(),
    );
  }
}
