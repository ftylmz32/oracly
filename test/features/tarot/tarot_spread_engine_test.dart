/// Spread engine — real layouts, labels, live pile binding.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_deck_controller.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/spread_engine.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('each offered spread has count, positions, labels, read order', () {
    const offered = [
      TarotSpreadType.single,
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
      TarotSpreadType.sevenCard,
    ];
    for (final type in offered) {
      final def = SpreadEngine.of(type);
      expect(def.cardCount, type.cardCount);
      expect(def.isConsistent, isTrue);
      expect(def.positions.length, type.cardCount);
      expect(def.interpretationOrder, List<int>.generate(type.cardCount, (i) => i));
      expect(
        def.interpretationSequence.map((p) => p.labelTr).toList(),
        def.positions.map((p) => p.labelTr).toList(),
      );
    }
  });

  test('position labels match the spread engine spec', () {
    expect(
      SpreadEngine.positionsFor(TarotSpreadType.single).map((p) => p.labelTr),
      ['Bugünün ana işareti'],
    );
    expect(
      SpreadEngine.positionsFor(TarotSpreadType.threeCard).map((p) => p.labelTr),
      ['Geçmiş', 'Şimdi', 'Gelecek'],
    );
    expect(
      SpreadEngine.positionsFor(TarotSpreadType.fiveCard).map((p) => p.labelTr),
      ['Durum', 'Gizli etki', 'Zorluk', 'Güç', 'Yön'],
    );
    expect(
      SpreadEngine.positionsFor(TarotSpreadType.sevenCard).map((p) => p.labelTr),
      [
        'Soru',
        'Şimdiki enerji',
        'Engel',
        'Gizli etken',
        'Yardımcı olan',
        'Kaçınılacak',
        'Yön',
      ],
    );
    expect(TarotPolishCopy.spreadThreeBlurb, contains('Gelecek'));
  });

  test('direction slots are symbolic, not a promised future', () {
    for (final type in [
      TarotSpreadType.fiveCard,
      TarotSpreadType.sevenCard,
    ]) {
      final direction = SpreadEngine.of(type)
          .positions
          .firstWhere((p) => p.key == 'direction');
      expect(direction.description!.toLowerCase(), contains('sembolik'));
      expect(
        direction.description!.toLowerCase(),
        anyOf(contains('kehanet değil'), contains('gelecek değil')),
      );
    }
    final future = SpreadEngine.of(TarotSpreadType.threeCard)
        .positions
        .firstWhere((p) => p.key == 'future');
    expect(future.description!.toLowerCase(), contains('sembolik'));
    expect(future.description!.toLowerCase(), contains('kehanet değil'));
  });

  test('incomplete spread does not invent cards', () {
    TarotCard stub(int id) => TarotCard(
          id: id,
          name: 'c$id',
          image: 'x',
          arcana: TarotArcana.major,
          suit: TarotSuit.none,
          number: id,
          summary: 's',
          meaning: 'u',
          reversedMeaning: 'r',
          keywords: const [],
        );
    final drawn = [
      TarotDrawnCard(card: stub(1), positionIndex: 0, isReversed: false),
      TarotDrawnCard(card: stub(2), positionIndex: 2, isReversed: true),
    ];
    final ordered = SpreadEngine.interpretationCards(
      spread: TarotSpreadType.fiveCard,
      drawn: drawn,
    );
    expect(ordered.map((c) => c.card.id), [1, 2]);
    expect(ordered.length, 2);
  });

  test('draws bind live pile cards onto spread slots', () async {
    final deck = TarotDeckController();
    await deck.initializeDeck(deckId: 'classic', seed: 21);
    final labels = SpreadEngine.positionsFor(TarotSpreadType.threeCard)
        .map((p) => p.labelTr)
        .toList();
    final expectedIds = [
      deck.drawPile[deck.drawPile.length - 1].id,
      deck.drawPile[deck.drawPile.length - 2].id,
      deck.drawPile[deck.drawPile.length - 3].id,
    ];
    for (var i = 0; i < 3; i++) {
      final draw = deck.drawNext();
      expect(draw.card.id, expectedIds[i]);
      expect(SpreadEngine.positionAt(TarotSpreadType.threeCard, i)?.labelTr, labels[i]);
    }
  });
}
