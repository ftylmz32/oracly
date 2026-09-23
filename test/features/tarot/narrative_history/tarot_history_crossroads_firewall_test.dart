/// Phase 5D.1 — Crossroads is not normalized as classical fiveCard by Phase 4.
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

  test('Crossroads session normalize skips — not classical.fiveCard', () {
    final result = TarotHistorySessionNormalize.normalize(
      session: _crossroadsSession(),
      linked: null,
      currentOwnerId: null,
    );
    expect(result.record, isNull);
    expect(result.diag.skippedMalformed, 1);
    expect(result.diag.skippedOwnerMismatch, 0);
  });

  test('legacy ReadingModel crossroads skips — not classical.fiveCard', () {
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
    expect(result.record, isNull);
    expect(result.diag.skippedMalformed, 1);
  });
}
