/// OR-1140 — Tarot reading domain model.
library;

import '../core/oracle_engine_type.dart';

class TarotCardDraw {
  const TarotCardDraw({
    required this.cardId,
    required this.positionIndex,
    required this.positionLabel,
    required this.isReversed,
  });

  final int cardId;
  final int positionIndex;
  final String positionLabel;
  final bool isReversed;
}

class TarotReading {
  const TarotReading({
    required this.id,
    required this.spreadType,
    required this.cards,
    required this.createdAt,
    this.intention,
    this.deckId = 'rider-waite',
  });

  final String id;
  final TarotSpreadType spreadType;
  final List<TarotCardDraw> cards;
  final DateTime createdAt;
  final String? intention;
  final String deckId;

  Map<String, dynamic> toFacts() => {
        'id': id,
        'spreadType': spreadType.name,
        'cardCount': cards.length,
        'cardIds': cards.map((c) => c.cardId).toList(),
        'reversed': cards.where((c) => c.isReversed).map((c) => c.cardId).toList(),
        'intention': intention,
        'deckId': deckId,
      };
}
