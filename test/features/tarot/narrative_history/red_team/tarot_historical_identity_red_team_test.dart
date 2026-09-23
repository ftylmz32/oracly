import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_theme_lexicon.dart';

import '../tarot_history_test_support.dart';

void main() {
  group('physical reading identity red-team', () {
    final now = nowFixed;

    List<String> ids(List<TarotHistoricalReadingRecord> rows) =>
        rows.map((r) => r.readingId).toList();

    test('same readingId twice → eligible 1', () {
      final t = now.subtract(const Duration(days: 1));
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [
          histReading(readingId: 'r1', at: t, cardId: major00),
          histReading(readingId: 'r1', at: t, cardId: major00),
        ],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out, hasLength(1));
    });

    test('different readingIds same sessionId → eligible 1', () {
      final t = now.subtract(const Duration(days: 1));
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [
          histReading(readingId: 'journal_1', sessionId: 'session_1', at: t),
          histReading(
            readingId: 'other_id',
            sessionId: 'session_1',
            at: t.subtract(const Duration(seconds: 1)),
          ),
        ],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out, hasLength(1));
      expect(out.single.readingId, 'journal_1'); // newest first kept
    });

    test('readingId ↔ sessionId cross match → eligible 1', () {
      final t = now.subtract(const Duration(days: 1));
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [
          histReading(readingId: 'journal_1', sessionId: 'session_1', at: t),
          histReading(
            readingId: 'session_1',
            sessionId: 'session_1',
            at: t.subtract(const Duration(hours: 1)),
          ),
        ],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out, hasLength(1));
    });

    test('duplicate physical same card → occurrenceCount 1; +second → 2', () {
      final base = baseRequest();
      final t = now.subtract(const Duration(days: 1));
      final one = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'journal_1',
              sessionId: 'session_1',
              at: t,
              cardId: major00,
            ),
            histReading(
              readingId: 'session_1',
              sessionId: 'session_1',
              at: t.subtract(const Duration(minutes: 1)),
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(one.eligiblePriorReadingCount, 1);
      expect(one.recurringCards.single.occurrenceCount, 1);

      final two = TarotCardRecurrenceEngine.build(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: [
            histReading(
              readingId: 'journal_1',
              sessionId: 'session_1',
              at: t,
              cardId: major00,
            ),
            histReading(
              readingId: 'session_1',
              sessionId: 'session_1',
              at: t.subtract(const Duration(minutes: 1)),
              cardId: major00,
            ),
            histReading(
              readingId: 'real_2',
              at: now.subtract(const Duration(days: 2)),
              cardId: major00,
            ),
          ],
        ),
        currentOwnerId: null,
        now: now,
      );
      expect(two.eligiblePriorReadingCount, 2);
      expect(two.recurringCards.single.occurrenceCount, 2);
    });

    test('dedupe before max20 — duplicates do not consume budget', () {
      final rows = <TarotHistoricalReadingRecord>[];
      // 19 unique + 6 duplicates of first identity = 25 input rows
      for (var i = 0; i < 19; i++) {
        rows.add(
          histReading(
            readingId: 'u${i.toString().padLeft(2, '0')}',
            at: now.subtract(Duration(days: i + 1)),
          ),
        );
      }
      for (var d = 0; d < 6; d++) {
        rows.add(
          histReading(
            readingId: 'u00',
            sessionId: 'dup_session',
            at: now.subtract(Duration(hours: d + 1)),
          ),
        );
      }
      expect(rows, hasLength(25));

      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out, hasLength(19)); // 19 distinct after dedupe (<20)
      expect(out.map((e) => e.readingId).toSet(), hasLength(19));

      // Add more uniques so after dedupe we still have >20
      for (var i = 19; i < 26; i++) {
        rows.add(
          histReading(
            readingId: 'u${i.toString().padLeft(2, '0')}',
            at: now.subtract(Duration(days: i + 1)),
          ),
        );
      }
      final out20 = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out20, hasLength(20));
      expect(out20.map((e) => e.readingId).toSet(), hasLength(20));
    });

    test('input reorder → identical selected identities', () {
      final rows = [
        histReading(
          readingId: 'journal_1',
          sessionId: 's1',
          at: now.subtract(const Duration(days: 1)),
        ),
        histReading(
          readingId: 's1',
          sessionId: 's1',
          at: now.subtract(const Duration(days: 2)),
        ),
        histReading(
          readingId: 'real_2',
          at: now.subtract(const Duration(days: 3)),
        ),
      ];
      List summarize(List<TarotHistoricalReadingRecord> input) {
        return ids(
          TarotHistoricalEligibility.eligibleTarotReadings(
            readings: input,
            currentReadingId: 'cur',
            currentSessionId: null,
            currentOwnerId: null,
            now: now,
            bounds: RequestBounds.defaults,
          ),
        );
      }

      expect(summarize(rows.reversed.toList()), summarize(rows));
    });

    test('aşk theme extraction; ask excluded', () {
      expect(
        TarotHistoricalThemeLexicon.themeIdsFromText(
          intentionSummary: 'Aşk konusunda ne yapmalıyım?',
        ),
        contains('ilişki'),
      );
      expect(
        TarotHistoricalThemeLexicon.themeIdsFromText(intentionSummary: 'aşk'),
        contains('ilişki'),
      );
      expect(
        TarotHistoricalThemeLexicon.themeIdsFromText(
          intentionSummary: 'Should I ask what they want?',
        ),
        isEmpty,
      );
      expect(
        TarotHistoricalThemeLexicon.themeIdsFromText(
          intentionSummary: 'ask them tomorrow',
        ),
        isEmpty,
      );
      expect(
        TarotHistoricalThemeLexicon.themeIdsFromText(
          intentionSummary: 'partner',
        ),
        contains('ilişki'),
      );
    });
  });
}
