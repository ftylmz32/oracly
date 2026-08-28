/// Integrity of the canonical 78-card ORACLY Tarot data layer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_assets.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_enums.dart';

void main() {
  final deck = OraclyTarotDeck.all;
  final ids = deck.map((c) => c.id).toList();

  test('exactly 78 unique cards — 22 major, 56 minor', () {
    expect(deck, hasLength(OraclyTarotDeck.expectedCount));
    expect(ids.toSet(), hasLength(78));
    expect(OraclyTarotDeck.majorArcana, hasLength(22));
    expect(OraclyTarotDeck.minorArcana, hasLength(56));
    expect(ids.toSet(), OraclyTarotDeck.expectedIds.toSet());
  });

  test('standard suits: 14 each, Ace–King numbering', () {
    for (final suit in [
      OraclyTarotSuit.wands,
      OraclyTarotSuit.cups,
      OraclyTarotSuit.swords,
      OraclyTarotSuit.pentacles,
    ]) {
      final cards = OraclyTarotDeck.bySuit(suit);
      expect(cards, hasLength(14));
      expect(cards.map((c) => c.number).toList(), [
        for (var n = 1; n <= 14; n++) n,
      ]);
      expect(cards.every((c) => c.isMinor), isTrue);
    }
    expect(
      OraclyTarotDeck.majorArcana.every(
        (c) => c.suit == OraclyTarotSuit.none && c.isMajor,
      ),
      isTrue,
    );
  });

  test('every card is complete and relations resolve', () {
    for (final card in deck) {
      expect(card.isComplete, isTrue, reason: card.id);
      expect(
        card.visualAsset,
        OraclyTarotAssets.visualFor(
          arcana: card.arcana,
          suit: card.suit,
          number: card.number,
        ),
      );
      expect(card.cardBackAsset, OraclyTarotAssets.cardBack);
      for (final related in card.relationshipWithOtherCards.relatedIds) {
        expect(OraclyTarotDeck.byId(related), isNotNull, reason: related);
      }
    }
  });
}
