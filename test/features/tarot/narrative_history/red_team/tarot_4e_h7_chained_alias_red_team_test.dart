/// Phase 4E.1 — H7 transitive physical-identity component collapse red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

import '../tarot_history_test_support.dart';

void main() {
  final now = nowFixed;

  TarotHistoricalReadingRecord row({
    required String readingId,
    required String sessionId,
    required int daysAgo,
    String? ownerId,
    String cardId = '',
    String? intentionSummary,
  }) {
    return histReading(
      readingId: readingId,
      sessionId: sessionId,
      at: now.subtract(Duration(days: daysAgo)),
      ownerId: ownerId,
      cardId: cardId.isEmpty ? major00 : cardId,
      intentionSummary: intentionSummary,
    );
  }

  List<String> ids(List<TarotHistoricalReadingRecord> rows) =>
      rows.map((r) => r.readingId).toList();

  List<TarotHistoricalReadingRecord> eligible(
    List<TarotHistoricalReadingRecord> readings, {
    String? currentOwnerId,
    String currentReadingId = 'cur_r',
    String? currentSessionId = 'cur_s',
    RequestBounds bounds = RequestBounds.defaults,
  }) {
    return TarotHistoricalEligibility.eligibleTarotReadings(
      readings: readings,
      currentReadingId: currentReadingId,
      currentSessionId: currentSessionId,
      currentOwnerId: currentOwnerId,
      now: now,
      bounds: bounds,
    );
  }

  group('H7 transitive component collapse', () {
    test('A↔B↔C chain collapses to newest A; A↛C pairwise remains false', () {
      final a = row(readingId: 'ra', sessionId: 'sab', daysAgo: 1);
      final b = row(readingId: 'rb', sessionId: 'sab', daysAgo: 2);
      final c = row(readingId: 'rb', sessionId: 'sbc', daysAgo: 3);
      expect(TarotHistoricalEligibility.samePhysicalIdentity(a, b), isTrue);
      expect(TarotHistoricalEligibility.samePhysicalIdentity(b, c), isTrue);
      expect(TarotHistoricalEligibility.samePhysicalIdentity(a, c), isFalse);
      final perms = [
        [a, b, c],
        [a, c, b],
        [b, a, c],
        [b, c, a],
        [c, a, b],
        [c, b, a],
      ];
      for (final perm in perms) {
        expect(ids(eligible(perm)), ['ra']);
      }
    });

    test('bridge-newest selects B as representative', () {
      final a = row(readingId: 'ra', sessionId: 'sab', daysAgo: 2);
      final b = row(readingId: 'rb', sessionId: 'sab', daysAgo: 1);
      final c = row(readingId: 'rb', sessionId: 'sbc', daysAgo: 3);
      expect(ids(eligible([a, b, c])), ['rb']);
    });

    test('5-row chain collapses to one; permutations stable', () {
      final rows = [
        row(readingId: 'r1', sessionId: 's12', daysAgo: 1),
        row(readingId: 'r2', sessionId: 's12', daysAgo: 2),
        row(readingId: 'r2', sessionId: 's23', daysAgo: 3),
        row(readingId: 'r3', sessionId: 's23', daysAgo: 4),
        row(readingId: 'r3', sessionId: 's34', daysAgo: 5),
      ];
      final expected = ['r1'];
      expect(ids(eligible(rows)), expected);
      expect(ids(eligible(rows.reversed.toList())), expected);
      expect(
        ids(eligible([rows[2], rows[4], rows[0], rows[3], rows[1]])),
        expected,
      );
    });

    test('two disconnected components remain two', () {
      final a = row(readingId: 'ra', sessionId: 'sa', daysAgo: 1);
      final b = row(readingId: 'rb', sessionId: 'sa', daysAgo: 2);
      final x = row(
        readingId: 'rx',
        sessionId: 'sx',
        daysAgo: 1,
        cardId: major01,
      );
      final y = row(
        readingId: 'ry',
        sessionId: 'sx',
        daysAgo: 3,
        cardId: major01,
      );
      expect(ids(eligible([a, b, x, y])), ['ra', 'rx']);
    });

    test('direct duplicates still collapse to one', () {
      final a = row(readingId: 'same', sessionId: 's1', daysAgo: 1);
      final b = row(readingId: 'same', sessionId: 's2', daysAgo: 2);
      expect(ids(eligible([a, b])), ['same']);
    });
  });
}
