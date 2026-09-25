/// Phase 8 — RESTART E / F: durable paid interpretation replay.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/services/tarot_session_interpretation_replay.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RESTART F — paid before journal: provider=0 same body', () async {
    final world = await TarotE2eWorld.create(gems: 100);
    final paidBody = cloneSolThreeForEmptySession();
    final firstAi = ScriptedNarrativeAi([AiOutcome.success(paidBody)]);
    final firstInterp = world.interpretation(firstAi, world.newCache());
    final firstCtrl = world.controller(firstInterp);

    final session = threeContrastSession(id: 'e2e_restart_f');
    await firstCtrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );

    final live = await world.completeViaController(firstCtrl, firstInterp);
    expect(live, isNotNull);
    expect(live!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(firstAi.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(firstCtrl.session!.interpretation, isNotNull);
    expect(firstCtrl.session!.interpretationResultMode, 'narrativeV2');
    expect(firstCtrl.session!.interpretationSource, isNotNull);
    expect(firstCtrl.session!.interpretationDeliveryKind, 'interpretation');
    expect(firstCtrl.session!.interpretationLocale, 'en');

    final paidProse = firstCtrl.session!.interpretation!;
    final fingerprint = _fingerprint(live);
    final walletAfterPay = world.authority.balance;
    await firstCtrl.flush();
    firstCtrl.dispose();

    final mutant = cloneSolThreeForEmptySession();
    mutant['summary'] = 'MUTANT_OPENING_MUST_NOT_APPEAR';
    mutant['synthesis'] = 'MUTANT_SYNTHESIS_MUST_NOT_APPEAR';
    final secondAi = ScriptedNarrativeAi([AiOutcome.success(mutant)]);
    final secondCache = world.newCache();
    expect(secondCache.writes, isEmpty);
    final secondInterp = world.interpretation(secondAi, secondCache);
    final secondCtrl = world.controller(secondInterp);
    await secondCtrl.restoreActiveSession();
    expect(secondCtrl.session!.id, session.id);
    expect(secondCtrl.session!.interpretation, paidProse);

    final restored =
        await world.completeViaController(secondCtrl, secondInterp);
    expect(secondAi.callCount, 0, reason: 'PAID-RESULT RESTART REPLAY');
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, walletAfterPay);
    expect(restored, isNotNull);
    expect(restored!.fullInterpretation, paidProse);
    expect(restored.fullInterpretation, isNot(contains('MUTANT_')));
    expect(_fingerprint(restored), fingerprint);
    expect(
      TarotSessionInterpretationReplay.resultModeOf(secondCtrl.session!),
      isNotNull,
    );
    secondCtrl.dispose();
  });

  test('RESTART E — unpaid snapshot: provider=0 then charge once', () async {
    final world = await TarotE2eWorld.create(gems: 100);
    final body = cloneSolThreeForEmptySession();
    final firstAi = ScriptedNarrativeAi([AiOutcome.success(body)]);
    final firstInterp = world.interpretation(firstAi, world.newCache());
    final firstCtrl = world.controller(firstInterp);
    final session = threeContrastSession(id: 'e2e_restart_e');
    await firstCtrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    // Simulate quality-passed persist before charge (controller path mid-load).
    final content = await firstCtrl.resolveInterpretationContent();
    expect(content.isJournalEligible, isTrue);
    expect(firstCtrl.session!.interpretation, isNotNull);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(firstAi.callCount, 1);
    final prose = firstCtrl.session!.interpretation!;
    await firstCtrl.flush();
    firstCtrl.dispose();

    final throwAi = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final secondInterp = world.interpretation(throwAi, world.newCache());
    final secondCtrl = world.controller(secondInterp);
    await secondCtrl.restoreActiveSession();
    expect(world.charge.alreadyCharged(session.id), isFalse);

    final settled =
        await world.completeViaController(secondCtrl, secondInterp);
    expect(throwAi.callCount, 0);
    expect(settled, isNotNull);
    expect(settled!.fullInterpretation, prose);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    secondCtrl.dispose();
  });

  test('RESTART F + throwing provider still opens paid body', () async {
    final world = await TarotE2eWorld.create();
    final firstAi = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final firstInterp = world.interpretation(firstAi, world.newCache());
    final firstCtrl = world.controller(firstInterp);
    final session = threeContrastSession(id: 'e2e_restart_f_throw');
    await firstCtrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(firstCtrl, firstInterp);
    final prose = firstCtrl.session!.interpretation!;
    await firstCtrl.flush();
    firstCtrl.dispose();

    final throwAi = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final secondInterp = world.interpretation(throwAi, world.newCache());
    final secondCtrl = world.controller(secondInterp);
    await secondCtrl.restoreActiveSession();
    final restored =
        await world.completeViaController(secondCtrl, secondInterp);
    expect(throwAi.callCount, 0);
    expect(restored!.fullInterpretation, prose);
    secondCtrl.dispose();
  });
}

String _fingerprint(AiReadingContent c) => [
      c.fullInterpretation,
      c.drawnCards.map((d) => '${d.card.id}:${d.isReversed}').join(','),
      c.userQuestion,
      c.deliveryKind.name,
      c.interpretationSource.name,
    ].join('|');
