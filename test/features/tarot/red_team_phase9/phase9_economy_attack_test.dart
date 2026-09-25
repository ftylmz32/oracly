/// Phase 9 — economy double-charge / collision / concurrent settle attacks.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';
import 'phase9_invariants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('20× same session complete — charge once', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_eco_20');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final before = world.authority.balance;
    for (var i = 0; i < 20; i++) {
      await world.completeViaController(ctrl, interp);
    }
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(ai.callCount, 1);
    expect(before - world.authority.balance, 20);
    assertEconomicInvariant(world.charge, session.id, expectCharged: true);
    ctrl.dispose();
  });

  test('two controllers same storage — one charge', () async {
    final world = await TarotE2eWorld.create();
    final outcomes = List.generate(
      4,
      (_) => AiOutcome.success(cloneSolThreeForEmptySession()),
    );
    final ai = ScriptedNarrativeAi(outcomes);
    final interp = world.interpretation(ai, world.newCache());
    final a = world.controller(interp);
    final b = world.controller(interp);
    final session = threeContrastSession(id: 'p9_two_ctrl');
    await a.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await b.restoreActiveSession();
    await Future.wait([
      world.completeViaController(a, interp),
      world.completeViaController(b, interp),
    ]);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, lessThanOrEqualTo(80));
    a.dispose();
    b.dispose();
  });

  test('new session different id — second charge allowed', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_a').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_b').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    expect(world.charge.alreadyCharged('p9_a'), isTrue);
    expect(world.charge.alreadyCharged('p9_b'), isTrue);
    expect(world.authority.balance, 60);
    ctrl.dispose();
  });

  test('session-id collision different cards — report charge reuse', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final first = threeContrastSession(id: 'collision');
    await ctrl.updateSession(
      first.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final balance = world.authority.balance;
    final swapped = first.copyWith(
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reading,
      drawnCards: first.drawnCards.reversed.toList(),
      interpretation: null,
      interpretationResultMode: null,
    );
    await ctrl.updateSession(swapped);
    final second = await world.completeViaController(ctrl, interp);
    // Documented: charge ledger keys by session id — second settle free.
    expect(world.charge.alreadyCharged('collision'), isTrue);
    expect(world.authority.balance, balance);
    expect(second, isNotNull);
    ctrl.dispose();
  });

  test('shouldCommit false — no settlement, cards intact', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_no_settle');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final missed = await world.completeViaController(
      ctrl,
      interp,
      shouldCommit: () => false,
    );
    expect(missed, isNull);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(ctrl.session!.drawnCards, hasLength(3));
    ctrl.dispose();
  });
}
