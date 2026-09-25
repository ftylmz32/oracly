/// Phase 9 — concurrent forceRefresh / identical content / dispose reinterpret.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';
import 'phase9_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent forceRefresh — one provider, no second charge', () async {
    final world = await TarotE2eWorld.create();
    final body = cloneSolThreeForEmptySession();
    final mutant = cloneSolThreeForEmptySession();
    mutant['summary'] = '${mutant['summary']} quieter second look.';
    final delayed = DelayedScriptedAi(
      [
        AiOutcome.success(body),
        AiOutcome.success(mutant),
        AiOutcome.success(mutant),
      ],
      delay: const Duration(milliseconds: 50),
    );
    final interp = world.interpretation(delayed, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_reint_race');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final balance = world.authority.balance;
    final a = ctrl.resolveInterpretationContent(forceRefresh: true);
    final b = ctrl.resolveInterpretationContent(forceRefresh: true);
    await Future.wait([a, b]);
    expect(delayed.callCount, 2);
    expect(world.authority.balance, balance);
    ctrl.dispose();
  });

  test('identical content — no duplicate version', () async {
    final world = await TarotE2eWorld.create();
    final versions = ReadingVersionService(ReadingVersionStore(world.storage));
    await versions.seedOriginal(
      rootId: 'p9_ver',
      kind: ReadingVersionKind.tarot,
      data: ReadingVersionPayload.tarot('same body'),
    );
    final dup = await versions.tryAppendRevision(
      rootId: 'p9_ver',
      kind: ReadingVersionKind.tarot,
      data: ReadingVersionPayload.tarot('same body'),
    );
    expect(dup.added, isFalse);
    expect(dup.group.entries, hasLength(1));
  });

  test('safety reinterpret — original preserved, provider=0', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    const prior = 'prior paid body must remain';
    final base = threeContrastSession(id: 'p9_reint_safe');
    await ctrl.updateSession(
      ReadingSession(
        id: base.id,
        deckId: base.deckId,
        spread: base.spread,
        intention: const TarotIntention(text: 'Intihar etmeyi düşünüyorum'),
        shuffleSeed: base.shuffleSeed,
        startedAt: base.startedAt,
        drawnCards: base.drawnCards,
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
        interpretation: prior,
      ),
    );
    final content = await ctrl.resolveInterpretationContent(forceRefresh: true);
    expect(content.isSafetyResponse, isTrue);
    expect(ctrl.session!.interpretation, prior);
    expect(ai.callCount, 0);
    ctrl.dispose();
  });

  test('dispose mid reinterpret — no crash', () async {
    final world = await TarotE2eWorld.create();
    final delayed = DelayedScriptedAi(
      [
        AiOutcome.success(cloneSolThreeForEmptySession()),
        AiOutcome.success(cloneSolThreeForEmptySession()),
      ],
      delay: const Duration(milliseconds: 100),
    );
    final interp = world.interpretation(delayed, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_reint_disp').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final pending = ctrl.resolveInterpretationContent(forceRefresh: true);
    ctrl.dispose();
    try {
      await pending;
    } catch (_) {}
  });
}
