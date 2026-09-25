/// Phase 9 — locale / flag chaos after paid settlement.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
import 'package:oracly_new/features/tarot/services/tarot_session_interpretation_replay.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';
import 'phase9_invariants.dart';

void _flag(bool on) => FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: on,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    FeatureFlagRuntime.refreshFromRemote(const {});
    OraclyL10n.bind('en');
  });

  test('TR→EN→RU flips after paid — body + locale stamp stable', () async {
    OraclyL10n.bind('en');
    _flag(true);
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_loc_flip').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    final before = ctrl.session;
    final prose = before!.interpretation!;
    expect(before.interpretationLocale, 'en');
    await ctrl.flush();
    ctrl.dispose();

    for (final loc in ['tr', 'en', 'ru']) {
      OraclyL10n.bind(loc);
      final throwAi = ScriptedNarrativeAi([AiOutcome.failure(AiFailure.network())]);
      final c = world.controller(world.interpretation(throwAi, world.newCache()));
      await c.restoreActiveSession();
      final r = await world.completeViaController(
        c,
        world.interpretation(throwAi, world.newCache()),
      );
      expect(throwAi.callCount, 0, reason: loc);
      expect(r!.fullInterpretation, prose);
      expect(c.session!.interpretationLocale, 'en');
      assertReplayBodyStable(before, c.session);
      c.dispose();
    }
  });

  test('flag mid-flow OFF after paid — mode stays V2', () async {
    _flag(true);
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(
      threeContrastSession(id: 'p9_flag_mid').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    expect(ctrl.session!.interpretationResultMode, 'narrativeV2');
    final prose = ctrl.session!.interpretation!;
    await ctrl.flush();
    ctrl.dispose();

    _flag(false);
    final throwAi = ScriptedNarrativeAi([AiOutcome.failure(AiFailure.network())]);
    final ctrl2 = world.controller(world.interpretation(throwAi, world.newCache()));
    await ctrl2.restoreActiveSession();
    final r = await world.completeViaController(
      ctrl2,
      world.interpretation(throwAi, world.newCache()),
    );
    expect(throwAi.callCount, 0);
    expect(r!.fullInterpretation, prose);
    expect(
      TarotSessionInterpretationReplay.resultModeOf(ctrl2.session!),
      ReadingResultMode.narrativeV2,
    );
    ctrl2.dispose();
  });
}
