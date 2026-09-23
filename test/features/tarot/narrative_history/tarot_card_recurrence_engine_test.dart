import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_00.dart';
import 'package:oracly_new/features/tarot/narrative/data/profiles/narrative_major_01.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotCardRecurrenceEngine', () {
    final now = nowFixed;

    test('no history / no card match → 0', () {
      final base = baseRequest();
      final empty = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(tarotReadings: const []),
        currentOwnerId: null,
        now: now,
      );
      expect(empty.recurringCards, isEmpty);
      expect(empty.eligiblePriorReadingCount, 0);

      final mismatch = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'h1',
              at: now.subtract(const Duration(days: 1)),
              cardId: major01,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(mismatch.recurringCards, isEmpty);
      expect(mismatch.eligiblePriorReadingCount, 1);
    });

    test('one prior same card; current reading not counted', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: base.readingId,
              at: now.subtract(const Duration(days: 1)),
              cardId: major00,
            ),
            histReading(
              readingId: 'h1',
              at: now.subtract(const Duration(days: 2)),
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.eligiblePriorReadingCount, 1);
      expect(result.recurringCards, hasLength(1));
      expect(result.recurringCards.single.occurrenceCount, 1);
      expect(result.recurringCards.single.evidenceId, 'rec_card_01');
      expect(result.recurringCards.single.canonicalCardId, major00);
    });

    test('three prior readings same card → count 3', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            for (var i = 1; i <= 3; i++)
              histReading(
                readingId: 'h$i',
                at: now.subtract(Duration(days: i)),
                cardId: major00,
              ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.recurringCards.single.occurrenceCount, 3);
    });

    test('duplicate same card in one reading counts once', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'dup',
              at: now.subtract(const Duration(days: 1)),
              cards: const [
                TarotHistoricalCardOccurrence(
                  canonicalCardId: 'major_00',
                  isReversed: true,
                  positionKey: 'b',
                  positionIndex: 2,
                ),
                TarotHistoricalCardOccurrence(
                  canonicalCardId: 'major_00',
                  isReversed: false,
                  positionKey: 'a',
                  positionIndex: 1,
                ),
              ],
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.eligiblePriorReadingCount, 1);
      expect(result.recurringCards.single.occurrenceCount, 1);
      expect(result.recurringCards.single.occurrences.single.positionKey, 'a');
    });

    test('ranking two current cards + evidence ids', () {
      final base = baseRequest(
        cards: [
          cardEvidence(kNarrativeMajor00, positionIndex: 0),
          cardEvidence(kNarrativeMajor01, positionIndex: 1, ritualCardId: 1),
        ],
      );
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'h1',
              at: now.subtract(const Duration(days: 1)),
              cardId: major01,
            ),
            histReading(
              readingId: 'h2',
              at: now.subtract(const Duration(days: 2)),
              cardId: major01,
            ),
            histReading(
              readingId: 'h3',
              at: now.subtract(const Duration(days: 3)),
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.recurringCards.map((e) => e.evidenceId).toList(), [
        'rec_card_01',
        'rec_card_02',
      ]);
      expect(result.recurringCards.first.canonicalCardId, major01);
      expect(result.recurringCards.first.occurrenceCount, 2);
      expect(result.recurringCards.last.canonicalCardId, major00);
      for (final e in result.recurringCards) {
        expect(
          base.cards.map((c) => c.canonicalCardId),
          contains(e.canonicalCardId),
        );
      }
    });

    test('samples max 5; count may exceed; newest first', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            for (var i = 1; i <= 8; i++)
              histReading(
                readingId: 'h$i',
                at: now.subtract(Duration(days: i)),
                cardId: major00,
              ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      final card = result.recurringCards.single;
      expect(card.occurrenceCount, 8);
      expect(card.occurrences, hasLength(5));
      expect(card.occurrences.first.readingId, 'h1');
      expect(card.occurrences.last.readingId, 'h5');
    });

    test('missing positionKey counts but omits sample', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'nopos',
              at: now.subtract(const Duration(days: 1)),
              cardId: major00,
              positionKey: null,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.recurringCards.single.occurrenceCount, 1);
      expect(result.recurringCards.single.occurrences, isEmpty);
    });

    test('orientation known / unknown', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'rev',
              at: now.subtract(const Duration(days: 1)),
              cardId: major00,
              isReversed: true,
              orientationKnown: true,
            ),
            histReading(
              readingId: 'up',
              at: now.subtract(const Duration(days: 2)),
              cardId: major00,
              isReversed: false,
              orientationKnown: true,
            ),
            histReading(
              readingId: 'unk',
              at: now.subtract(const Duration(days: 3)),
              cardId: major00,
              isReversed: false,
              orientationKnown: false,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      final samples = result.recurringCards.single.occurrences;
      expect(samples[0].orientationKnown, isTrue);
      expect(samples[0].isReversed, isTrue);
      expect(samples[1].orientationKnown, isTrue);
      expect(samples[1].isReversed, isFalse);
      expect(samples[2].orientationKnown, isFalse);
      // Sentinel only — not factual upright.
      expect(samples[2].isReversed, isFalse);
    });

    test('does not mutate base request shells', () {
      final base = baseRequest();
      TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'h1',
              at: now.subtract(const Duration(days: 1)),
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(base.recurringCards, isEmpty);
      expect(base.recurringThemes, isEmpty);
      expect(base.relationships, isEmpty);
      expect(base.memory.included, isFalse);
    });

    test('context strongest across priors', () {
      final base = baseRequest(topic: 'ilişki');
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'newer',
              at: now.subtract(const Duration(days: 1)),
              cardId: major00,
            ),
            histReading(
              readingId: 'older',
              at: now.subtract(const Duration(days: 5)),
              cardId: major00,
              topicId: 'ilişki',
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.recurringCards.single.contextsOverlap, isTrue);
      expect(result.recurringCards.single.overlapSummaryKey, 'topic_match');
    });
  });
}
