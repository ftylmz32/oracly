/// Phase 5D.1 / 6B — Crossroads history as signature.crossroads; never fiveCard.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_card_normalize.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_legacy_normalize.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_session_normalize.dart';

const _card = TarotCard(
  id: 0,
  name: 'The Fool',
  image: 'fool.png',
  arcana: TarotArcana.major,
  suit: TarotSuit.none,
  number: 0,
  summary: 's',
  meaning: 'm',
  reversedMeaning: 'r',
  keywords: ['k'],
);

const _keys = ['option_a', 'option_b', 'tension', 'counsel', 'direction'];

ReadingSession _crossroadsSession() {
  final at = DateTime.utc(2026, 9, 22, 12);
  return ReadingSession(
    id: 'sess-cr',
    deckId: 'rider-waite',
    spread: TarotSpreadType.crossroads,
    intention: const TarotIntention(text: 'Which path feels honest?'),
    shuffleSeed: 1,
    status: ReadingSessionStatus.completed,
    startedAt: at,
    completedAt: at,
    drawnCards: [
      for (var i = 0; i < 5; i++)
        TarotDrawnCard(
          card: _card,
          isReversed: false,
          positionIndex: i,
          positionKey: 'p$i',
        ),
    ],
    interpretation: 'Stored interpretation stays put.',
  );
}

void main() {
  test('classicalFromSpread(crossroads) is null — never fiveCard', () {
    expect(
      TarotHistoryCardNormalize.classicalFromSpread(TarotSpreadType.crossroads),
      isNull,
    );
    final five = TarotHistoryCardNormalize.classicalFromSpread(
      TarotSpreadType.fiveCard,
    );
    expect(five?.spreadId, 'classical.fiveCard');
  });

  test('supported history resolution returns signature.crossroads', () {
    final s = TarotHistoryCardNormalize.supportedFromSpread(
      TarotSpreadType.crossroads,
    );
    expect(s?.spreadId, 'signature.crossroads');
    expect(s?.legacyTypeName, 'crossroads');
    expect(s?.cardCount, 5);
  });

  test('Crossroads session normalizes as Signature — never fiveCard', () {
    final result = TarotHistorySessionNormalize.normalize(
      session: _crossroadsSession(),
      linked: null,
      currentOwnerId: null,
    );
    expect(result.record, isNotNull);
    expect(result.record!.spreadId, 'signature.crossroads');
    expect(result.record!.spreadId, isNot('classical.fiveCard'));
    expect(
      result.record!.cards.map((c) => c.positionKey).toList(),
      _keys,
    );
    expect(result.diag.skippedMalformed, 0);
  });

  test('legacy ReadingModel Crossroads normalizes as Signature', () {
    final result = TarotHistoryLegacyNormalize.normalize(
      reading: ReadingModel(
        id: 'legacy-cr',
        cardId: 0,
        cardName: 'The Fool',
        cardImageAsset: 'fool.png',
        spreadType: 'crossroads',
        aiSummary: 'Stored summary.',
        createdAt: DateTime.utc(2026, 9, 22),
        cards: [
          for (var i = 0; i < 5; i++)
            ReadingCardSnapshot(
              cardId: 0,
              cardName: 'The Fool',
              cardImageAsset: 'fool.png',
              isReversed: false,
              positionIndex: i,
            ),
        ],
      ),
      currentOwnerId: null,
    );
    expect(result.record, isNotNull);
    expect(result.record!.spreadId, 'signature.crossroads');
    expect(result.record!.spreadId, isNot('classical.fiveCard'));
    expect(result.diag.skippedMalformed, 0);
  });
}
