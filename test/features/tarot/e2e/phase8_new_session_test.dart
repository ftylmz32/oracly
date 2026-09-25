/// Phase 8.2 — new reading identity + abandon active + concurrent load.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new reading after paid — new id, new charge, no free ride', () async {
    final world = await TarotE2eWorld.create(gems: 100);
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final old = threeContrastSession(id: 'e2e_old_done');
    await ctrl.updateSession(
      old.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    expect(world.charge.alreadyCharged(old.id), isTrue);
    final walletAfterOld = world.authority.balance;
    await ctrl.completeSession();

    final next = threeContrastSession(id: 'e2e_new_after');
    await ctrl.updateSession(
      next.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    expect(ctrl.session!.id, isNot(old.id));
    final content = await world.completeViaController(ctrl, interp);
    expect(content, isNotNull);
    expect(world.charge.alreadyCharged(next.id), isTrue);
    expect(world.charge.alreadyCharged(old.id), isTrue);
    expect(world.authority.balance, lessThan(walletAfterOld));
    expect(ai.callCount, 2);
    ctrl.dispose();
  });

  test('abandonActiveForNewStart clears unfinished session', () async {
    final world = await TarotE2eWorld.create();
    final ctrl = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(cloneSolThreeForEmptySession())]),
        world.newCache(),
      ),
    );
    await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    final oldId = ctrl.session!.id;
    await ctrl.advanceToShuffle();
    await ctrl.performShuffle();
    await ctrl.finishShuffle();
    await ctrl.drawCard();
    expect(ctrl.session!.drawnCards, hasLength(1));
    await ctrl.abandonActiveForNewStart();
    expect(ctrl.session, isNull);
    await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    expect(ctrl.session!.id, isNot(oldId));
    expect(ctrl.session!.drawnCards, isEmpty);
    expect(ctrl.session!.interpretation, isNull);
    ctrl.dispose();
  });

  test('concurrent resolveInterpretationContent coalesces', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_concurrent');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final a = ctrl.resolveInterpretationContent();
    final b = ctrl.resolveInterpretationContent();
    final ra = await a;
    final rb = await b;
    expect(identical(ra, rb) || ra.fullInterpretation == rb.fullInterpretation, isTrue);
    expect(ai.callCount, 1);
    ctrl.dispose();
  });
}
