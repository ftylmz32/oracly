/// Phase 8 — flag flip + locale flip after paid result (restart replay).
/// REAL PROVIDER CALLS = 0.
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
import 'tarot_e2e_harness.dart';

void _setFlag(bool on) => FeatureFlagRuntime.refreshFromRemote({
      ProductFeatureFlags.tarotNarrativeV2.key: on,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => FeatureFlagRuntime.refreshFromRemote(const {}));

  test('flag OFF after paid Narrative — mode stays V2, provider=0', () async {
    _setFlag(true);
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_flag_off');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    expect(ctrl.session!.interpretationResultMode, 'narrativeV2');
    final prose = ctrl.session!.interpretation!;
    await ctrl.flush();
    ctrl.dispose();

    _setFlag(false);
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
      ReadingResultMode.narrativeV2,
    );
    ctrl2.dispose();
  });

  test('locale flip TR after EN paid — body unchanged, provider=0', () async {
    OraclyL10n.bind('en');
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_locale');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    expect(ctrl.session!.interpretationLocale, 'en');
    final prose = ctrl.session!.interpretation!;
    await ctrl.flush();
    ctrl.dispose();

    OraclyL10n.bind('tr');
    final throwAi = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final second = world.interpretation(throwAi, world.newCache());
    final ctrl2 = world.controller(second);
    await ctrl2.restoreActiveSession();
    final restored = await world.completeViaController(ctrl2, second);
    expect(throwAi.callCount, 0);
    expect(restored!.fullInterpretation, prose);
    expect(ctrl2.session!.interpretationLocale, 'en');
    OraclyL10n.bind('en');
    ctrl2.dispose();
  });
}
