/// Phase 4E.1 — H7 bridge rejection, bounds, no-merge, downstream counts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_card_recurrence_engine.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';

import '../tarot_history_test_support.dart';

void main() {
  final now = nowFixed;

  TarotHistoricalReadingRecord row({
    required String readingId,
    required String sessionId,
    required int daysAgo,
    String? ownerId,
    String? intentionSummary,
  }) {
    return histReading(
      readingId: readingId,
      sessionId: sessionId,
      at: now.subtract(Duration(days: daysAgo)),
      ownerId: ownerId,
      cardId: major00,
      intentionSummary: intentionSummary,
    );
  }

  List<String> ids(List<TarotHistoricalReadingRecord> rows) =>
      rows.map((r) => r.readingId).toList();

  group('H7 rejected bridges cannot join eligible rows', () {
    test('foreign-owner bridge rejected', () {
      final left = row(
        readingId: 'L',
        sessionId: 'bridge',
        daysAgo: 1,
        ownerId: 'A',
      );
      final bridge = row(
        readingId: 'B',
        sessionId: 'bridge',
        daysAgo: 2,
        ownerId: 'X',
      );
      final right = row(
        readingId: 'B',
        sessionId: 'right',
        daysAgo: 3,
        ownerId: 'A',
      );
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [left, bridge, right],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: 'A',
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['L', 'B']);
    });

    test('current-reading bridge rejected', () {
      // Bridge is current via sessionId only; left/right stay eligible.
      final left = row(readingId: 'L', sessionId: 'sab', daysAgo: 1);
      final bridge = row(readingId: 'mid', sessionId: 'cur_s', daysAgo: 2);
      final right = row(readingId: 'mid', sessionId: 'sbc', daysAgo: 3);
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [left, bridge, right],
        currentReadingId: 'cur_r',
        currentSessionId: 'cur_s',
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['L', 'mid']);
    });

    test('out-of-lookback bridge rejected', () {
      final left = row(readingId: 'L', sessionId: 'bridge', daysAgo: 1);
      final bridge = row(readingId: 'B', sessionId: 'bridge', daysAgo: 91);
      final right = row(readingId: 'B', sessionId: 'right', daysAgo: 2);
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [left, bridge, right],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['L', 'B']);
    });

    test('future bridge rejected', () {
      final left = row(readingId: 'L', sessionId: 'bridge', daysAgo: 1);
      final future = histReading(
        readingId: 'B',
        sessionId: 'bridge',
        at: now.add(const Duration(days: 1)),
        cardId: major00,
      );
      final right = row(readingId: 'B', sessionId: 'right', daysAgo: 2);
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [left, future, right],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['L', 'B']);
    });
  });

  group('H7 bounds / no-merge / downstream', () {
    test('max-20 applied after component collapse', () {
      final rows = <TarotHistoricalReadingRecord>[
        for (var i = 0; i < 25; i++)
          row(readingId: 'solo_$i', sessionId: 's$i', daysAgo: i + 1),
        row(readingId: 'chain_a', sessionId: 'cx', daysAgo: 1),
        row(readingId: 'chain_b', sessionId: 'cx', daysAgo: 2),
        row(readingId: 'chain_b', sessionId: 'cy', daysAgo: 3),
      ];
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out, hasLength(20));
      expect(out.where((r) => r.readingId.startsWith('chain')).length, 1);
    });

    test('no field merge — representative payload only', () {
      final newest = row(
        readingId: 'ra',
        sessionId: 'sab',
        daysAgo: 1,
        intentionSummary: 'newest-only intention',
      );
      final mid = histReading(
        readingId: 'rb',
        sessionId: 'sab',
        at: now.subtract(const Duration(days: 2)),
        cardId: major01,
        intentionSummary: 'bridge intention',
      );
      final old = histReading(
        readingId: 'rb',
        sessionId: 'sbc',
        at: now.subtract(const Duration(days: 3)),
        cardId: major06,
        intentionSummary: 'oldest intention',
      );
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [newest, mid, old],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out, hasLength(1));
      expect(out.single.intentionSummary, 'newest-only intention');
      expect(out.single.cards.single.canonicalCardId, major00);
    });

    test('priorReadingCount and occurrenceCount not inflated', () {
      final base = baseRequest();
      final history = TarotHistoricalSnapshot(
        tarotReadings: [
          row(readingId: 'ra', sessionId: 'sab', daysAgo: 1),
          row(readingId: 'rb', sessionId: 'sab', daysAgo: 2),
          row(readingId: 'rb', sessionId: 'sbc', daysAgo: 3),
        ],
      );
      final card = TarotCardRecurrenceEngine.build(
        base: base,
        history: history,
        currentOwnerId: null,
        now: now,
      );
      expect(card.eligiblePriorReadingCount, 1);
      expect(card.recurringCards, hasLength(1));
      expect(card.recurringCards.single.occurrenceCount, 1);

      final en1 = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: history,
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      final en2 = TarotNarrativeRequestEnricher.enrich(
        base: base,
        history: TarotHistoricalSnapshot(
          tarotReadings: history.tarotReadings.reversed.toList(),
        ),
        currentOwnerId: null,
        privacyBlocked: false,
        now: now,
      );
      expect(en1.memory.priorReadingCount, 1);
      expect(en2.memory.priorReadingCount, 1);
      expect(
        en1.recurringCards.map((e) => e.evidenceId).toList(),
        en2.recurringCards.map((e) => e.evidenceId).toList(),
      );
    });
  });
}
