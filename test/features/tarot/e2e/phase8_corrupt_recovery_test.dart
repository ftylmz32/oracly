/// Phase 8.2 — corrupt / overfull / partial-reading recovery.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_session_recovery.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_shadow/narrative_shadow_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrupt raw JSON — decode null, no invent', () {
    expect(TarotSessionRecovery.decode('{not json'), isNull);
    expect(TarotSessionRecovery.decode('[]'), isNull);
    expect(TarotSessionRecovery.decode(''), isNull);
  });

  test('empty id rejected', () {
    final s = threeContrastSession(id: '  ');
    expect(TarotSessionRecovery.prepare(s), isNull);
    final json = threeContrastSession().toJson()..['id'] = '';
    expect(ReadingSession.tryFromJson(json), isNull);
  });

  test('overfull threeCard clamps to 3', () {
    final base = threeContrastSession(id: 'overfull');
    final extra = [
      ...base.drawnCards,
      TarotDrawnCard(
        card: ritualCard(2),
        positionIndex: 3,
        isReversed: false,
        positionKey: 'extra',
      ),
    ];
    final fat = base.copyWith(drawnCards: extra);
    expect(fat.drawnCards, hasLength(4));
    final fixed = TarotSessionRecovery.prepare(fat)!;
    expect(fixed.drawnCards, hasLength(3));
    expect(fixed.drawnCards.map((c) => c.card.id).toSet(), hasLength(3));
  });

  test('partial reading step repaired away from reading', () {
    final base = threeContrastSession(id: 'partial_read');
    final partial = ReadingSession(
      id: base.id,
      deckId: base.deckId,
      spread: base.spread,
      intention: base.intention,
      shuffleSeed: base.shuffleSeed,
      startedAt: base.startedAt,
      drawnCards: [base.drawnCards.first],
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reading,
      currentPositionIndex: 99,
    );
    final fixed = TarotSessionRecovery.prepare(partial)!;
    expect(fixed.flowStep, isNot(ReadingFlowStep.reading));
    expect(fixed.drawnCards, hasLength(1));
    expect(fixed.currentPositionIndex, 0);
  });

  test('completed not restored when activeOnly', () {
    final done = threeContrastSession(id: 'done').copyWith(
      status: ReadingSessionStatus.completed,
      flowStep: ReadingFlowStep.completed,
    );
    expect(TarotSessionRecovery.prepare(done, activeOnly: true), isNull);
    expect(TarotSessionRecovery.prepare(done, activeOnly: false), isNotNull);
  });

  test('malformed map via decode', () {
    expect(
      TarotSessionRecovery.decode(jsonEncode({'id': 'x', 'spread': 'nope'})),
      isNull,
    );
  });
}
