/// Phase 8 — canonical paid happy paths (controller integration).
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('happy single — one provider, one charge', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured(callIndex: 0)),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = singleFoolSession(id: 'e2e_single_happy');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final content = await world.completeViaController(ctrl, interp);
    expect(content, isNotNull);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(ai.callCount, 1);
    // One-card is free — no settle ledger entry.
    expect(TarotEconomy.isFree(TarotSpreadType.single), isTrue);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, 100);
    expect(ctrl.session!.drawnCards.length, 1);
    expect(ctrl.session!.interpretationResultMode, 'narrativeV2');
    ctrl.dispose();
  });

  test('happy threeCard — one provider, one charge, session identity', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_three_happy');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final content = await world.completeViaController(ctrl, interp);
    expect(content, isNotNull);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(ai.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(ctrl.session!.id, session.id);
    expect(ctrl.session!.drawnCards.length, 3);
    expect(
      ReadingResultModeResolver.of(TarotSpreadType.threeCard),
      ReadingResultMode.narrativeV2,
    );
    final ids = ctrl.session!.drawnCards.map((c) => c.card.id).toSet();
    expect(ids.length, 3);
    expect(
      ReadingResultModeResolver.of(TarotSpreadType.crossroads),
      ReadingResultMode.legacy,
    );
    ctrl.dispose();
  });
}
