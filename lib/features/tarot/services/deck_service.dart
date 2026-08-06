/// OR-1170 — Deck generation from content catalogue.
library;

import 'dart:math';

import '../../content/tarot/data/tarot_content_catalogue.dart';
import '../../content/tarot/models/tarot_card_content.dart';
import '../models/tarot_card.dart';

class DeckService {
  const DeckService();

  static const deckIdMap = {
    'classic': 'rider-waite',
    'golden': 'oracly-gold',
    'moon_oracle': 'mystic-moon',
    'mystic_dreams': 'mystic-dreams',
    'ancient_wisdom': 'ancient-wisdom',
    'future_visions': 'future-visions',
  };

  String resolveDeckId(String uiDeckId) =>
      deckIdMap[uiDeckId] ?? uiDeckId;

  List<TarotCard> createDeck({String deckId = 'rider-waite'}) {
    return TarotContentCatalogue.all.map(_fromContent).toList();
  }

  List<TarotCard> shuffledDeck({
    required int seed,
    String deckId = 'rider-waite',
  }) {
    final deck = createDeck(deckId: deckId);
    deck.shuffle(Random(seed));
    return deck;
  }

  TarotCard _fromContent(TarotCardContent content) {
    return TarotCard(
      id: content.id,
      name: content.nameTr,
      image: content.imageAsset,
      arcana: content.arcana == TarotContentArcana.major
          ? TarotArcana.major
          : TarotArcana.minor,
      suit: _mapSuit(content.suit),
      number: content.number,
      summary: content.uprightMeaning,
      meaning: content.uprightMeaning,
      reversedMeaning: content.reversedMeaning,
      keywords: content.keywords,
      element: content.element,
      planet: content.planet,
      zodiac: content.zodiac,
    );
  }

  TarotSuit _mapSuit(TarotContentSuit suit) => switch (suit) {
        TarotContentSuit.cups => TarotSuit.cups,
        TarotContentSuit.pentacles => TarotSuit.pentacles,
        TarotContentSuit.swords => TarotSuit.swords,
        TarotContentSuit.wands => TarotSuit.wands,
        TarotContentSuit.none => TarotSuit.none,
      };
}
