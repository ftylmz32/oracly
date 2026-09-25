/// Phase 9 — concurrent interpretation / dispose / session-replace races.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';
import 'phase9_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('2 concurrent resolveInterpretationContent share one inflight', () async {
    final world = await TarotE2eWorld.create();
    final delayed = DelayedScriptedAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(delayed, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_race2').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final a = ctrl.resolveInterpretationContent();
    final b = ctrl.resolveInterpretationContent();
    final ra = await a;
    final rb = await b;
    expect(
      identical(ra, rb) || ra.fullInterpretation == rb.fullInterpretation,
      isTrue,
    );
    expect(delayed.callCount, 1);
    ctrl.dispose();
  });

  test('10 concurrent resolves — single provider call', () async {
    final world = await TarotE2eWorld.create();
    final delayed = DelayedScriptedAi(
      [AiOutcome.success(cloneSolThreeForEmptySession())],
      delay: const Duration(milliseconds: 40),
    );
    final interp = world.interpretation(delayed, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_race10').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final futures =
        List.generate(10, (_) => ctrl.resolveInterpretationContent());
    await Future.wait(futures);
    expect(delayed.callCount, 1);
    ctrl.dispose();
  });

  test('dispose mid-future — no crash', () async {
    final world = await TarotE2eWorld.create();
    final delayed = DelayedScriptedAi(
      [AiOutcome.success(cloneSolThreeForEmptySession())],
      delay: const Duration(milliseconds: 100),
    );
    final interp = world.interpretation(delayed, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_dispose').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final pending = ctrl.resolveInterpretationContent();
    ctrl.dispose();
    try {
      await pending;
    } catch (_) {}
  });

  test('session replace while old Future returns — fail closed', () async {
    final world = await TarotE2eWorld.create();
    final delayed = DelayedScriptedAi(
      [AiOutcome.success(cloneSolThreeForEmptySession())],
      delay: const Duration(milliseconds: 80),
    );
    final interp = world.interpretation(delayed, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_old').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final pending = ctrl.resolveInterpretationContent();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_new').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await expectLater(pending, throwsA(isA<StateError>()));
    expect(ctrl.session!.id, 'p9_new');
    expect(ctrl.session!.interpretation, isNull);
    ctrl.dispose();
  });
}
