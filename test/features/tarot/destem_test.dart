/// Destem — 78-card informational deck, no fake unlocks.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_enums.dart';
import 'package:oracly_new/features/tarot/presentation/destem/destem_copy.dart';
import 'package:oracly_new/features/tarot/presentation/destem/destem_seen.dart';

void main() {
  test('canonical deck exposes all 78 cards with artwork and meaning', () {
    final all = OraclyTarotDeck.all;
    expect(all, hasLength(78));
    expect(OraclyTarotDeck.majorArcana, hasLength(22));
    expect(OraclyTarotDeck.minorArcana, hasLength(56));
    expect(OraclyTarotDeck.bySuit(OraclyTarotSuit.wands), hasLength(14));
    expect(OraclyTarotDeck.bySuit(OraclyTarotSuit.cups), hasLength(14));
    expect(OraclyTarotDeck.bySuit(OraclyTarotSuit.swords), hasLength(14));
    expect(OraclyTarotDeck.bySuit(OraclyTarotSuit.pentacles), hasLength(14));
    for (final card in all) {
      expect(card.visualAsset, isNotEmpty, reason: card.id);
      expect(card.visualAsset, startsWith('assets/tarot/cards/'));
      expect(card.symbolicMeaning.tr.trim(), isNotEmpty, reason: card.id);
      expect(card.name.tr.trim(), isNotEmpty, reason: card.id);
    }
  });

  test('seen state comes only from real reading history', () {
    final seen = DestemSeen.fromReadings([
      ReadingModel(
        id: 'r1',
        cardId: 0,
        cardName: 'The Fool',
        cardImageAsset: 'x',
        spreadType: 'Tek Kart',
        aiSummary: '',
        createdAt: DateTime(2026, 8, 1),
        cards: const [
          ReadingCardSnapshot(
            cardId: 22,
            cardName: 'Ace',
            cardImageAsset: 'y',
            positionIndex: 0,
          ),
        ],
      ),
    ]);
    expect(seen, contains('major_00'));
    expect(seen.length, greaterThanOrEqualTo(2));
    expect(seen, isNot(contains('major_21')));
  });

  test('destem copy states the collection is informational', () {
    OraclyL10n.bind('tr');
    expect(DestemCopy.title, 'Destem');
    expect(DestemCopy.subtitle.toLowerCase(), contains('bilgilendirme'));
    expect(DestemCopy.subtitle.toLowerCase(), contains('kilitli değildir'));
    OraclyL10n.bind('en');
    expect(DestemCopy.subtitle.toLowerCase(), contains('reference'));
    expect(DestemCopy.subtitle.toLowerCase(), contains('not locked'));
  });
}
