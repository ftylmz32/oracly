/// Transactional settle for [TarotRitualController] (Phase 7D.1).
library;

import 'package:flutter/widgets.dart';

import '../domain/models/reading_session.dart';
import '../shared/tarot_scope.dart';
import 'ritual_settle_outcome.dart';
import 'tarot_ritual_controller.dart';
import 'tarot_ritual_stage.dart';

extension TarotRitualSettle on TarotRitualController {
  /// Domain advance first — visual ownership transfers only on success.
  ///
  /// On failure: [active] stays, [placed] unchanged, stage stays reveal.
  /// Retry must call this again — never [commitDraw] / drawCard.
  Future<RitualSettleOutcome> settleAfterReveal(BuildContext context) async {
    final card = active;
    if (card == null) return RitualSettleOutcome.failed;
    if (settling) return RitualSettleOutcome.busy;
    settling = true;
    notifyVisual();
    try {
      final reading = TarotScope.of(context).reading;
      try {
        await reading.advanceAfterReveal();
      } catch (_) {
        return RitualSettleOutcome.failed;
      }
      placed.add(card);
      active = null;
      committedVisualId = null;
      visual = visual.copyWith(
        stage: TarotRitualStage.place,
        dragProgress: 0,
        extractionProgress: 0,
        flipProgress: 0,
      );
      notifyVisual();
      final session = reading.session;
      if (session == null) return RitualSettleOutcome.failed;
      if (session.flowStep == ReadingFlowStep.reading ||
          session.allCardsDrawn) {
        return RitualSettleOutcome.readingReady;
      }
      visual = visual.copyWith(stage: TarotRitualStage.draw);
      notifyVisual();
      return RitualSettleOutcome.continueDraw;
    } finally {
      settling = false;
      notifyVisual();
    }
  }
}
