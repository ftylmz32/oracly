/// Phase 8.2 — legacy paid + flag ON must not become Narrative.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
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

  test('legacy paid + flag ON — stays legacy, provider=0', () async {
    final world = await TarotE2eWorld.create();
    _setFlag(true);
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_legacy_flag_on');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    expect(live, isNotNull);
    // Persist as legacy historical truth (already charged).
    const body = '## Summary\nLegacy purchased body forever.\n\n## Closing\nStay.';
    await ctrl.updateSession(
      ctrl.session!.copyWith(
        interpretation: body,
        interpretationResultMode: 'legacy',
        interpretationSource: 'ai',
        interpretationDeliveryKind: 'interpretation',
        interpretationLocale: 'en',
      ),
    );
    await ctrl.flush();
    final wallet = world.authority.balance;
    ctrl.dispose();

    _setFlag(true);
    final throwAi = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final second = world.interpretation(throwAi, world.newCache());
    final ctrl2 = world.controller(second);
    await ctrl2.restoreActiveSession();
    final restored = await world.completeViaController(ctrl2, second);
    expect(throwAi.callCount, 0);
    expect(restored!.fullInterpretation, body);
    expect(
      TarotSessionInterpretationReplay.resultModeOf(ctrl2.session!),
      ReadingResultMode.legacy,
    );
    expect(world.authority.balance, wallet);
    ctrl2.dispose();
  });
}
