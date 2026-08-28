/// Repair unfinished tarot sessions so restore never invents cards.
library;

import 'dart:convert';

import 'reading_session.dart';

abstract final class TarotSessionRecovery {
  TarotSessionRecovery._();

  static ReadingSession? decode(String? raw, {bool activeOnly = false}) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return prepare(ReadingSession.fromJson(json), activeOnly: activeOnly);
    } catch (_) {
      return null;
    }
  }

  static ReadingSession? prepare(
    ReadingSession? session, {
    bool activeOnly = false,
  }) {
    if (session == null) return null;
    if (session.id.trim().isEmpty) return null;
    if (session.status == ReadingSessionStatus.completed) {
      return activeOnly ? null : session;
    }

    final limit = session.requiredCardCount;
    final cards = session.drawnCards.length > limit
        ? session.drawnCards.take(limit).toList()
        : session.drawnCards;
    var step = session.flowStep;
    if (cards.isEmpty &&
        (step == ReadingFlowStep.reveal || step == ReadingFlowStep.reading)) {
      step = ReadingFlowStep.cardSelection;
    }
    if (step == ReadingFlowStep.reading && cards.length < limit) {
      step = cards.isEmpty
          ? ReadingFlowStep.cardSelection
          : ReadingFlowStep.reveal;
    }
    final index = cards.isEmpty
        ? 0
        : session.currentPositionIndex.clamp(0, cards.length - 1);
    return session.copyWith(
      drawnCards: cards,
      flowStep: step,
      currentPositionIndex: index,
    );
  }
}
