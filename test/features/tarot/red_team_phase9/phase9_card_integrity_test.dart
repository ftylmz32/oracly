/// Phase 9 — card integrity / position key attacks.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_session_recovery.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import 'phase9_invariants.dart';
import 'phase9_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('duplicate card ids in raw JSON — recovery clamps, no invent', () {
    final recovered = TarotSessionRecovery.decode(corruptJson((m) {
      final cards = (m['drawnCards'] as List).toList();
      cards.add(Map<String, dynamic>.from(cards.first as Map));
      m['drawnCards'] = cards;
      return m;
    }))!;
    expect(recovered.drawnCards.length, lessThanOrEqualTo(3));
    assertDrawWithinSpread(recovered);
    for (final c in recovered.drawnCards) {
      expect(c.card.id, isA<int>());
    }
  });

  test('Crossroads keys on fiveCard history must not rewrite spread', () {
    final raw = fiveCardSession(id: 'p9_xr_keys').toJson();
    final cards = (raw['drawnCards'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    const xr = ['option_a', 'option_b', 'tension', 'counsel', 'direction'];
    for (var i = 0; i < cards.length; i++) {
      cards[i]['positionKey'] = xr[i];
    }
    raw['drawnCards'] = cards;
    final recovered = TarotSessionRecovery.decode(jsonEncode(raw));
    if (recovered == null) return;
    expect(recovered.spread, TarotSpreadType.fiveCard);
    expect(recovered.spread, isNot(TarotSpreadType.crossroads));
    expect(recovered.drawnCards.length, lessThanOrEqualTo(5));
  });

  test('position index gaps / scrambled indices clamp safely', () {
    final gap = TarotSessionRecovery.decode(corruptJson((m) {
      final cards = (m['drawnCards'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      cards[0]['positionIndex'] = 0;
      cards[1]['positionIndex'] = 7;
      cards[2]['positionIndex'] = 2;
      m['drawnCards'] = cards;
      m['currentPositionIndex'] = 99;
      return m;
    }))!;
    expect(
      gap.currentPositionIndex,
      inInclusiveRange(0, gap.drawnCards.length - 1),
    );
    assertDrawWithinSpread(gap);
  });
}
