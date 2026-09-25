/// Phase 9 — replay / unpaid body / provenance / flag attacks.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/services/tarot_session_interpretation_replay.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';
import 'phase9_invariants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('unpaid body + 0 gems — no free paid display', () async {
    final world = await TarotE2eWorld.create(gems: 0);
    final session = threeContrastSession(id: 'p9_unpaid_free').copyWith(
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reading,
      interpretation: '## Summary\nstolen body',
      interpretationResultMode: 'narrativeV2',
      interpretationSource: 'ai',
      interpretationDeliveryKind: 'interpretation',
    );
    expect(TarotSessionInterpretationReplay.hasPersistedBody(session), isTrue);
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final content = await world.completePaid(session, world.interpretation(ai, world.newCache()));
    expect(content, isNull);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(ai.callCount, 0);
  });

  test('paid + mutant AI — body stable, provider=0', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_mutant');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final before = ctrl.session;
    final prose = before!.interpretation!;
    await ctrl.flush();
    ctrl.dispose();

    final mutant = cloneSolThreeForEmptySession();
    mutant['summary'] = 'MUTANT_MUST_NOT_SHOW';
    final ai2 = ScriptedNarrativeAi([AiOutcome.success(mutant)]);
    final interp2 = world.interpretation(ai2, world.newCache());
    final ctrl2 = world.controller(interp2);
    await ctrl2.restoreActiveSession();
    final restored = await world.completeViaController(ctrl2, interp2);
    expect(ai2.callCount, 0);
    expect(restored!.fullInterpretation, prose);
    assertReplayBodyStable(before, ctrl2.session);
    ctrl2.dispose();
  });

  test('corrupt body after settlement — no second charge', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_corrupt_body');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final balance = world.authority.balance;
    await ctrl.updateSession(
      ctrl.session!.copyWith(interpretation: '## Summary\nmutated after pay'),
    );
    final again = await world.completeViaController(ctrl, interp);
    expect(again!.fullInterpretation, '## Summary\nmutated after pay');
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, balance);
    expect(ai.callCount, 1);
    ctrl.dispose();
  });

  test('invalid provenance strings — replay no crash', () {
    final s = threeContrastSession(id: 'p9_prov').copyWith(
      interpretation: 'raw body without structure',
      interpretationResultMode: 'notAMode',
      interpretationSource: '???',
      interpretationDeliveryKind: 'bogus',
    );
    final content = TarotSessionInterpretationReplay.tryBuild(s);
    expect(content, isNotNull);
    expect(content!.fullInterpretation, 'raw body without structure');
  });

  test('flag+locale flip after paid — provider=0', () async {
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: true,
    });
    OraclyL10n.bind('en');
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_flag_loc').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final prose = ctrl.session!.interpretation!;
    await ctrl.flush();
    ctrl.dispose();
    FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: false,
    });
    OraclyL10n.bind('tr');
    final ai2 = ScriptedNarrativeAi([AiOutcome.failure(AiFailure.network())]);
    final ctrl2 = world.controller(world.interpretation(ai2, world.newCache()));
    await ctrl2.restoreActiveSession();
    final r = await world.completeViaController(
      ctrl2,
      world.interpretation(ai2, world.newCache()),
    );
    expect(ai2.callCount, 0);
    expect(r!.fullInterpretation, prose);
    OraclyL10n.bind('en');
    ctrl2.dispose();
  });
}
