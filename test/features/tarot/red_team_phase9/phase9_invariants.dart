/// Phase 9 — test-only session/economy/replay invariant assertions.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';

void assertNoDuplicateCards(ReadingSession session) {
  final ids = session.drawnCards.map((c) => c.card.id).toList();
  expect(ids.toSet().length, ids.length, reason: 'duplicate card ids');
}

void assertDrawWithinSpread(ReadingSession session) {
  expect(
    session.drawnCards.length,
    lessThanOrEqualTo(session.requiredCardCount),
    reason: 'draw overflow',
  );
}

void assertSessionDeckConsistent(TarotReadingController ctrl) {
  final s = ctrl.session;
  if (s == null) return;
  assertDrawWithinSpread(s);
  assertNoDuplicateCards(s);
  final drawn = s.drawnCards.map((c) => c.card.id).toSet();
  for (final c in ctrl.deckController.drawPile) {
    expect(drawn.contains(c.id), isFalse, reason: 'deck still holds drawn id');
  }
}

void assertEconomicInvariant(
  TarotReadingCharge charge,
  String sessionId, {
  required bool expectCharged,
}) {
  expect(charge.alreadyCharged(sessionId), expectCharged);
}

void assertReplayBodyStable(ReadingSession? before, ReadingSession? after) {
  expect(after?.interpretation, before?.interpretation);
  expect(after?.interpretationResultMode, before?.interpretationResultMode);
  expect(after?.interpretationSource, before?.interpretationSource);
  expect(
    after?.interpretationDeliveryKind,
    before?.interpretationDeliveryKind,
  );
}
