/// Phase 9 — session state corruption attacks.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_session_recovery.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import 'phase9_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unknown spread / empty id → null; bad startedAt soft-defaults', () {
    expect(
      TarotSessionRecovery.decode(corruptJson((m) {
        m['spread'] = 'notASpread';
        return m;
      })),
      isNull,
    );
    expect(
      TarotSessionRecovery.decode(corruptJson((m) {
        m['id'] = '';
        return m;
      })),
      isNull,
    );
    // Codec contract: invalid startedAt → DateTime.now() (not null).
    final softDate = TarotSessionRecovery.decode(corruptJson((m) {
      m['startedAt'] = 'not-a-date';
      return m;
    }));
    expect(softDate, isNotNull);
  });

  test('bad indices / overfull / partial reading repaired safely', () {
    final over = TarotSessionRecovery.decode(corruptJson((m) {
      m['currentPositionIndex'] = 999;
      final cards = (m['drawnCards'] as List).toList();
      cards.add(cards.first);
      m['drawnCards'] = cards;
      return m;
    }))!;
    expect(over.drawnCards.length, lessThanOrEqualTo(3));
    expect(over.currentPositionIndex, inInclusiveRange(0, 2));

    final partial = TarotSessionRecovery.prepare(
      threeContrastSession(id: 'partial').copyWith(
        drawnCards: [threeContrastSession().drawnCards.first],
        flowStep: ReadingFlowStep.reading,
        currentPositionIndex: -1,
      ),
    )!;
    expect(partial.flowStep, isNot(ReadingFlowStep.reading));
    expect(partial.drawnCards, hasLength(1));
    expect(partial.currentPositionIndex, 0);
  });

  test('negative index / empty reading / completed incomplete', () {
    final neg = TarotSessionRecovery.decode(corruptJson((m) {
      m['currentPositionIndex'] = -40;
      return m;
    }))!;
    expect(neg.currentPositionIndex, greaterThanOrEqualTo(0));

    final emptyRead = TarotSessionRecovery.prepare(
      ReadingSession(
        id: 'empty_read',
        deckId: 'classic',
        spread: TarotSpreadType.threeCard,
        intention: const TarotIntention(text: ''),
        shuffleSeed: 1,
        startedAt: DateTime.utc(2026, 9, 25),
        drawnCards: const [],
        flowStep: ReadingFlowStep.reading,
      ),
    )!;
    expect(emptyRead.flowStep, ReadingFlowStep.cardSelection);
    expect(emptyRead.drawnCards, isEmpty);

    final doneIncomplete = threeContrastSession(id: 'done_bad').copyWith(
      status: ReadingSessionStatus.completed,
      flowStep: ReadingFlowStep.completed,
      drawnCards: [threeContrastSession().drawnCards.first],
    );
    expect(
      TarotSessionRecovery.prepare(doneIncomplete, activeOnly: true),
      isNull,
    );
  });

  test('provenance without body / Crossroads not aliased to fiveCard', () {
    final noBody = TarotSessionRecovery.decode(corruptJson((m) {
      m['interpretation'] = null;
      m['interpretationResultMode'] = 'narrativeV2';
      return m;
    }));
    expect(noBody, isNotNull);
    expect(noBody!.interpretation, isNull);

    final alias = TarotSessionRecovery.decode(corruptJson((m) {
      m['spread'] = 'crossroads';
      return m;
    }));
    if (alias != null) {
      expect(alias.spread, isNot(TarotSpreadType.fiveCard));
    }
  });

  test('malformed raw fail-closed; minimal map soft-decodes empty cards', () {
    expect(TarotSessionRecovery.decode('{'), isNull);
    expect(TarotSessionRecovery.decode('[]'), isNull);
    final soft = TarotSessionRecovery.decode(
      jsonEncode({'id': 'x', 'spread': 'threeCard'}),
    );
    expect(soft, isNotNull);
    expect(soft!.drawnCards, isEmpty);
  });
}
