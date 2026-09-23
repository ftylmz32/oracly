import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';

import '../tarot_history_test_support.dart';

void main() {
  group('card recurrence red-team', () {
    final now = nowFixed;

    test('malformed duplicate card in one reading → count 1 then 2', () {
      final base = baseRequest();
      final dup = histReading(
        readingId: 'dup',
        at: now.subtract(const Duration(days: 1)),
        cards: const [
          TarotHistoricalCardOccurrence(
            canonicalCardId: 'major_00',
            isReversed: false,
            positionKey: 'z',
            positionIndex: 5,
          ),
          TarotHistoricalCardOccurrence(
            canonicalCardId: 'major_00',
            isReversed: true,
            orientationKnown: false,
            positionKey: 'a',
            positionIndex: 1,
          ),
        ],
      );
      final one = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(tarotReadings: [dup]),
        currentOwnerId: null,
        now: now,
      );
      expect(one.eligiblePriorReadingCount, 1);
      expect(one.recurringCards.single.occurrenceCount, 1);

      final two = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            dup,
            histReading(
              readingId: 'second',
              at: now.subtract(const Duration(days: 2)),
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(two.recurringCards.single.occurrenceCount, 2);
    });

    test('determinism under reorder', () {
      final base = baseRequest();
      final rows = [
        histReading(
          readingId: 'b',
          at: now.subtract(const Duration(days: 1)),
          cardId: major00,
          topicId: 'ilişki',
        ),
        histReading(
          readingId: 'a',
          at: now.subtract(const Duration(days: 1)),
          cardId: major00,
        ),
        histReading(
          readingId: 'c',
          at: now.subtract(const Duration(days: 3)),
          cardId: major00,
        ),
      ];

      List summarize(List<TarotHistoricalReadingRecord> input) {
        final eligible = TarotHistoricalEligibility.eligibleTarotReadings(
          readings: input,
          currentReadingId: base.readingId,
          currentSessionId: base.sessionId,
          currentOwnerId: null,
          now: now,
          bounds: RequestBounds.defaults,
        );
        final result = TarotCardRecurrenceEngine.build(
          base: baseRequest(topic: 'ilişki'),
          history: TarotHistoricalSnapshot(tarotReadings: input),
          currentOwnerId: null,
          now: now,
        );
        final card = result.recurringCards.single;
        return [
          eligible.map((e) => e.readingId).toList(),
          card.evidenceId,
          card.occurrenceCount,
          card.occurrences.map((o) => o.readingId).toList(),
          card.contextsOverlap,
          card.overlapSummaryKey,
        ];
      }

      final forward = summarize(rows);
      final reversed = summarize(rows.reversed.toList());
      expect(reversed, forward);
    });

    test('empty canonicalCardId occurrence skipped', () {
      final base = baseRequest();
      final result = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'bad',
              at: now.subtract(const Duration(days: 1)),
              cards: const [
                TarotHistoricalCardOccurrence(
                  canonicalCardId: '',
                  isReversed: false,
                  positionKey: 'sign',
                ),
                TarotHistoricalCardOccurrence(
                  canonicalCardId: 'major_00',
                  isReversed: false,
                  positionKey: 'sign',
                  positionIndex: 0,
                ),
              ],
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(result.recurringCards.single.occurrenceCount, 1);
    });

    test('no DateTime.now in history production (static firewall sample)', () {
      // Pure engine accepts injected clock only.
      final earlier = now.subtract(const Duration(days: 10));
      final base = baseRequest();
      final mid = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'future_for_earlier',
              at: now,
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: earlier,
      );
      expect(mid.recurringCards, isEmpty);
      expect(mid.eligiblePriorReadingCount, 0);
    });
  });
}
