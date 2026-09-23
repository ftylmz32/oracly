import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';

import 'tarot_history_test_support.dart';

void main() {
  group('TarotHistoricalEligibility', () {
    final now = nowFixed;

    List<String> ids(List readings) =>
        readings.map((r) => r.readingId as String).toList();

    test(
      'same owner include / different exclude / owner-bound excludes ownerless',
      () {
        final rows = [
          histReading(
            readingId: 'a',
            at: now.subtract(const Duration(days: 1)),
            ownerId: 'u1',
          ),
          histReading(
            readingId: 'b',
            at: now.subtract(const Duration(days: 2)),
            ownerId: 'u2',
          ),
          histReading(
            readingId: 'c',
            at: now.subtract(const Duration(days: 3)),
          ),
        ];
        final out = TarotHistoricalEligibility.eligibleTarotReadings(
          readings: rows,
          currentReadingId: 'cur',
          currentSessionId: null,
          currentOwnerId: 'u1',
          now: now,
          bounds: RequestBounds.defaults,
        );
        expect(ids(out), ['a']);
      },
    );

    test('anonymous includes null-owner only', () {
      final rows = [
        histReading(readingId: 'a', at: now.subtract(const Duration(days: 1))),
        histReading(
          readingId: 'b',
          at: now.subtract(const Duration(days: 2)),
          ownerId: 'u1',
        ),
      ];
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['a']);
    });

    test('current readingId and sessionId excluded', () {
      final rows = [
        histReading(
          readingId: 'cur_r',
          at: now.subtract(const Duration(days: 1)),
        ),
        histReading(
          readingId: 'other',
          sessionId: 'cur_s',
          at: now.subtract(const Duration(days: 2)),
        ),
        histReading(readingId: 'ok', at: now.subtract(const Duration(days: 3))),
      ];
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur_r',
        currentSessionId: 'cur_s',
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['ok']);
    });

    test('exact 90 days include; +1us exclude; future exclude', () {
      final exact = histReading(
        readingId: 'exact',
        at: now.subtract(const Duration(days: 90)),
      );
      final tooOld = histReading(
        readingId: 'old',
        at: now.subtract(const Duration(days: 90, microseconds: 1)),
      );
      final future = histReading(
        readingId: 'fut',
        at: now.add(const Duration(seconds: 1)),
      );
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: [exact, tooOld, future],
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['exact']);
    });

    test('sort newest first; same timestamp readingId ASC', () {
      final t = now.subtract(const Duration(days: 1));
      final rows = [
        histReading(readingId: 'b', at: t),
        histReading(readingId: 'a', at: t),
        histReading(readingId: 'c', at: now.subtract(const Duration(hours: 1))),
      ];
      final out = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(ids(out), ['c', 'a', 'b']);
    });

    test('>20 eligible → take 20; bound 0 → empty', () {
      final rows = [
        for (var i = 0; i < 25; i++)
          histReading(
            readingId: 'r${i.toString().padLeft(2, '0')}',
            at: now.subtract(Duration(days: i + 1)),
          ),
      ];
      final out20 = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: RequestBounds.defaults,
      );
      expect(out20, hasLength(20));
      expect(out20.first.readingId, 'r00');

      final empty = TarotHistoricalEligibility.eligibleTarotReadings(
        readings: rows,
        currentReadingId: 'cur',
        currentSessionId: null,
        currentOwnerId: null,
        now: now,
        bounds: const RequestBounds(
          maxPriorReadingsScanned: 0,
          maxRecurringOccurrencesListed: 5,
          maxRelationships: 12,
          maxMemoryChars: 800,
          maxThemeLabels: 4,
        ),
      );
      expect(empty, isEmpty);
    });
  });
}
