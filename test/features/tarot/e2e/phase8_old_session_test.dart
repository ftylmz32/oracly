/// Phase 8 — legacy sessions: body without provenance fields.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
import 'package:oracly_new/features/tarot/services/tarot_session_interpretation_replay.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old paid body, no provenance — provider=0 legacy mode', () async {
    final world = await TarotE2eWorld.create();
    final firstAi = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final first = world.interpretation(firstAi, world.newCache());
    final ctrl = world.controller(first);
    final session = threeContrastSession(id: 'e2e_old_paid');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, first);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    // Strip provenance via JSON — pre-8.1 active session shape.
    final json = ctrl.session!.toJson()
      ..['interpretation'] = live!.fullInterpretation
      ..remove('interpretationResultMode')
      ..remove('interpretationSource')
      ..remove('interpretationDeliveryKind')
      ..remove('interpretationLocale');
    final stripped = ReadingSession.tryFromJson(json)!;
    await ctrl.updateSession(stripped);
    final prose = ctrl.session!.interpretation!;
    expect(ctrl.session!.interpretationResultMode, isNull);
    await ctrl.flush();
    ctrl.dispose();

    final throwAi = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final second = world.interpretation(throwAi, world.newCache());
    final ctrl2 = world.controller(second);
    await ctrl2.restoreActiveSession();
    final restored = await world.completeViaController(ctrl2, second);
    expect(throwAi.callCount, 0);
    expect(restored!.fullInterpretation, prose);
    expect(
      TarotSessionInterpretationReplay.resultModeOf(ctrl2.session!),
      ReadingResultMode.legacy,
    );
    expect(restored.sourceAttributionKnown, isFalse);
    ctrl2.dispose();
  });

  test('old unpaid body — CASE B charges, provider=0', () async {
    final world = await TarotE2eWorld.create();
    final before = world.authority.balance;
    const body = '## Summary\nLegacy unpaid snapshot.';
    final base = threeContrastSession(id: 'e2e_old_unpaid');
    final session = ReadingSession(
      id: base.id,
      deckId: base.deckId,
      spread: base.spread,
      intention: base.intention,
      shuffleSeed: base.shuffleSeed,
      startedAt: base.startedAt,
      drawnCards: base.drawnCards,
      interpretation: body,
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reading,
    );
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(session);

    final settled = await world.completeViaController(ctrl, interp);
    expect(ai.callCount, 0, reason: 'CASE B replays body — no provider');
    expect(settled, isNotNull);
    expect(settled!.fullInterpretation, body);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, lessThan(before));
    expect(
      TarotSessionInterpretationReplay.resultModeOf(ctrl.session!),
      ReadingResultMode.legacy,
    );
    ctrl.dispose();
  });
}
