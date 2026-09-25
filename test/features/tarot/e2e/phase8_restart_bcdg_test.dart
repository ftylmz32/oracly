/// Phase 8.2 — Restart B/C/D/G + deck continuity.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

Map<String, dynamic> _cloneSolFive() {
  final clone = cloneSolStructured(callIndex: 4);
  clone['relationshipInsights'] = <dynamic>[];
  clone['recurringCardInsights'] = <dynamic>[];
  clone['recurringThemeInsights'] = <dynamic>[];
  clone['memoryInsights'] = <dynamic>[];
  clone['lifeAreas'] = <dynamic>[];
  return clone;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RESTART B — one of three kept; final count 3 no dup', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    final sid = ctrl.session!.id;
    final seed = ctrl.session!.shuffleSeed;
    await ctrl.advanceToShuffle();
    await ctrl.performShuffle();
    await ctrl.finishShuffle();
    final first = await ctrl.drawCard();
    expect(ctrl.session!.drawnCards, hasLength(1));
    await ctrl.flush();
    ctrl.dispose();

    final ctrl2 = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(cloneSolThreeForEmptySession())]),
        world.newCache(),
      ),
    );
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session!.id, sid);
    expect(ctrl2.session!.shuffleSeed, seed);
    expect(ctrl2.session!.drawnCards, hasLength(1));
    expect(ctrl2.session!.drawnCards.first.card.id, first.card.id);
    expect(ctrl2.session!.drawnCards.first.isReversed, first.isReversed);

    await ctrl2.drawCard();
    await ctrl2.drawCard();
    expect(ctrl2.session!.drawnCards, hasLength(3));
    final ids = ctrl2.session!.drawnCards.map((c) => c.card.id).toList();
    expect(ids.toSet(), hasLength(3));
    expect(ids.first, first.card.id);
    ctrl2.dispose();
  });

  test('RESTART C — partial five retained; final 5 no dup', () async {
    final world = await TarotE2eWorld.create();
    final ctrl = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(_cloneSolFive())]),
        world.newCache(),
      ),
    );
    await ctrl.beginSession(spread: TarotSpreadType.fiveCard, deckId: 'classic');
    final sid = ctrl.session!.id;
    await ctrl.advanceToShuffle();
    await ctrl.performShuffle();
    await ctrl.finishShuffle();
    final a = await ctrl.drawCard();
    final b = await ctrl.drawCard();
    final before = [a.card.id, b.card.id];
    await ctrl.flush();
    ctrl.dispose();

    final ctrl2 = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(_cloneSolFive())]),
        world.newCache(),
      ),
    );
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session!.id, sid);
    expect(ctrl2.session!.drawnCards.map((c) => c.card.id).toList(), before);
    while (!ctrl2.session!.allCardsDrawn) {
      await ctrl2.drawCard();
    }
    expect(ctrl2.session!.drawnCards, hasLength(5));
    expect(ctrl2.session!.drawnCards.map((c) => c.card.id).toSet(), hasLength(5));
    ctrl2.dispose();
  });

  test('RESTART D — all drawn no result; no redraw; one charge on resume', () async {
    final world = await TarotE2eWorld.create();
    final session = threeContrastSession(id: 'e2e_restart_d');
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    expect(ctrl.session!.drawnCards, hasLength(3));
    expect(ctrl.session!.interpretation, isNull);
    await ctrl.flush();
    final ids = ctrl.session!.drawnCards.map((c) => c.card.id).toList();
    ctrl.dispose();

    final ai2 = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp2 = world.interpretation(ai2, world.newCache());
    final ctrl2 = world.controller(interp2);
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session!.drawnCards.map((c) => c.card.id).toList(), ids);
    expect(ctrl2.session!.interpretation, isNull);
    final content = await world.completeViaController(ctrl2, interp2);
    expect(content, isNotNull);
    expect(ai2.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(ctrl2.session!.drawnCards, hasLength(3));
    ctrl2.dispose();
  });

  test('RESTART G — after complete; active gone; history authoritative', () async {
    final world = await TarotE2eWorld.create();
    final session = threeContrastSession(id: 'e2e_restart_g');
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final content = await world.completeViaController(ctrl, interp);
    await ctrl.updateSession(
      ctrl.session!.copyWith(interpretation: content!.fullInterpretation),
    );
    await ctrl.completeSession();
    expect(ctrl.session!.status, ReadingSessionStatus.completed);
    await ctrl.flush();
    ctrl.dispose();

    final ctrl2 = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(cloneSolThreeForEmptySession())]),
        world.newCache(),
      ),
    );
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session, isNull);
    ctrl2.dispose();
  });
}
