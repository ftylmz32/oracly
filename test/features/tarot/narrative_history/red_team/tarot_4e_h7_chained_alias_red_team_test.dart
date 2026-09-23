/// Phase 4E audit — H7 physical-identity chained-alias red-team (no production fix).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_eligibility.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';

import '../tarot_history_test_support.dart';

void main() {
  final now = nowFixed;

  /// Non-transitive alias chain:
  /// A↔B via sessionId, B↔C via readingId, A↔C no direct match.
  /// Spec H7: one physical reading must survive — greedy pairwise keep can
  /// retain both A and C when B is dropped as the bridge.
  test('H7 MAJOR: non-transitive alias chain must not double-count', () {
    final a = histReading(
      readingId: 'ra',
      sessionId: 'sab',
      at: now.subtract(const Duration(days: 1)),
      cardId: major00,
    );
    final b = histReading(
      readingId: 'rb',
      sessionId: 'sab',
      at: now.subtract(const Duration(days: 2)),
      cardId: major00,
    );
    final c = histReading(
      readingId: 'rb',
      sessionId: 'sbc',
      at: now.subtract(const Duration(days: 3)),
      cardId: major00,
    );

    expect(TarotHistoricalEligibility.samePhysicalIdentity(a, b), isTrue);
    expect(TarotHistoricalEligibility.samePhysicalIdentity(b, c), isTrue);
    expect(TarotHistoricalEligibility.samePhysicalIdentity(a, c), isFalse);

    final eligible = TarotHistoricalEligibility.eligibleTarotReadings(
      readings: [a, b, c],
      currentReadingId: 'cur_r',
      currentSessionId: 'cur_s',
      currentOwnerId: null,
      now: now,
      bounds: RequestBounds.defaults,
    );

    // Contract: one physical reading in the chain → eligible length == 1.
    // Current greedy newest-first pairwise dedupe keeps A then C (length 2).
    expect(
      eligible.length,
      1,
      reason:
          'H7 chained aliases A–B–C must collapse to one physical reading; '
          'got ${eligible.map((e) => e.readingId).toList()}',
    );
  });

  test('H7: when bridge row is newest, single survivor is expected', () {
    final a = histReading(
      readingId: 'ra',
      sessionId: 'sab',
      at: now.subtract(const Duration(days: 2)),
      cardId: major00,
    );
    final b = histReading(
      readingId: 'rb',
      sessionId: 'sab',
      at: now.subtract(const Duration(days: 1)),
      cardId: major00,
    );
    final c = histReading(
      readingId: 'rb',
      sessionId: 'sbc',
      at: now.subtract(const Duration(days: 3)),
      cardId: major00,
    );
    final eligible = TarotHistoricalEligibility.eligibleTarotReadings(
      readings: [a, b, c],
      currentReadingId: 'cur_r',
      currentSessionId: 'cur_s',
      currentOwnerId: null,
      now: now,
      bounds: RequestBounds.defaults,
    );
    expect(eligible, hasLength(1));
    expect(eligible.single.readingId, 'rb');
  });
}
