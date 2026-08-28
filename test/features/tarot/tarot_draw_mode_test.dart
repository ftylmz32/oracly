/// Draw mode — real pile, fan mapping, frozen orientation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_deck_controller.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session_draw.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('draw mode copy exists', () {
    expect(TarotPolishCopy.drawManual, 'KARTI BEN ÇEKEYİM');
    expect(TarotPolishCopy.drawOr, 'KARTLARI ÇEK');
    expect(TarotPolishCopy.drawManualBlurb, 'Desteden bir kart çek.');
  });

  test('fan slot draws that pile card, not a substitute', () async {
    final deck = TarotDeckController();
    await deck.initializeDeck(deckId: 'classic', seed: 42);
    final fan = deck.fanCards;
    expect(fan.length, TarotDeckController.fanLimit);
    final chosen = fan[2];
    final drawn = deck.drawFromFan(2);
    expect(drawn.card.id, chosen.id);
    expect(deck.drawPile.any((c) => c.id == chosen.id), isFalse);
  });

  test('different fan positions are different remaining cards', () async {
    final deck = TarotDeckController();
    await deck.initializeDeck(deckId: 'classic', seed: 42);
    final a = deck.fanCards[0];
    final b = deck.fanCards[6];
    expect(a.id, isNot(b.id));
    final first = deck.drawFromFan(0);
    expect(first.card.id, a.id);
    expect(deck.drawPile.any((c) => c.id == b.id), isTrue);
  });

  test('OR draw takes the actual top of the shuffled pile', () async {
    final deck = TarotDeckController();
    await deck.initializeDeck(deckId: 'classic', seed: 7);
    final top = deck.drawPile.last;
    final drawn = deck.drawNext();
    expect(drawn.card.id, top.id);
  });

  test('OR draws sequential remaining tops, never substitutes', () async {
    final deck = TarotDeckController();
    await deck.initializeDeck(deckId: 'classic', seed: 11);
    final expected = [
      deck.drawPile[deck.drawPile.length - 1].id,
      deck.drawPile[deck.drawPile.length - 2].id,
      deck.drawPile[deck.drawPile.length - 3].id,
    ];
    expect(deck.drawNext().card.id, expected[0]);
    expect(deck.drawNext().card.id, expected[1]);
    expect(deck.drawNext().card.id, expected[2]);
  });

  test('orientation is decided at draw and stays put', () async {
    final first = TarotDeckController();
    await first.initializeDeck(deckId: 'classic', seed: 99);
    final second = TarotDeckController();
    await second.initializeDeck(deckId: 'classic', seed: 99);
    final a = first.drawFromFan(3);
    final b = second.drawFromFan(3);
    expect(a.card.id, b.card.id);
    expect(a.isReversed, b.isReversed);

    final frozen = TarotDrawnCard(
      card: a.card,
      positionIndex: 0,
      isReversed: a.isReversed,
    );
    expect(frozen.isReversed, a.isReversed);
    expect(frozen.effectiveMeaning, isNotEmpty);
  });

  test('queued reveal walks already-drawn cards without redrawing', () {
    TarotCard stub(int id) => TarotCard(
          id: id,
          name: 'c$id',
          image: 'x',
          arcana: TarotArcana.major,
          suit: TarotSuit.none,
          rank: TarotRank.none,
          number: id,
          summary: 's',
          meaning: 'u',
          reversedMeaning: 'r',
          keywords: const [],
        );
    final session = ReadingSession(
      id: 's',
      deckId: 'classic',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(text: ''),
      shuffleSeed: 1,
      startedAt: DateTime(2026, 1, 1),
      drawnCards: [
        TarotDrawnCard(
          card: stub(1),
          positionIndex: 0,
          isReversed: false,
        ),
        TarotDrawnCard(
          card: stub(2),
          positionIndex: 1,
          isReversed: true,
        ),
        TarotDrawnCard(
          card: stub(3),
          positionIndex: 2,
          isReversed: false,
        ),
      ],
      flowStep: ReadingFlowStep.reveal,
    );
    expect(session.hasQueuedReveal, isTrue);
    expect(session.drawnCards[1].isReversed, isTrue);
    expect(session.currentCard?.isReversed, isFalse);
  });
}
