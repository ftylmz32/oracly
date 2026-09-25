/// Phase 8 — safety restart: no paid envelope / journal / charge.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SAFETY RESTART — no envelope, no journal, no charge', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final base = threeContrastSession(id: 'e2e_safety_restart');
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
      ),
    );
    final first = await world.completeViaController(ctrl, interp);
    expect(first!.deliveryKind, TarotReadingDeliveryKind.safety);
    expect(first.isJournalEligible, isFalse);
    expect(ctrl.session!.interpretation, isNull);
    expect(world.charge.alreadyCharged(base.id), isFalse);
    await ctrl.flush();
    final ids = ctrl.session!.drawnCards.map((c) => c.card.id).toList();
    ctrl.dispose();

    final ai2 = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp2 = world.interpretation(ai2, world.newCache());
    final ctrl2 = world.controller(interp2);
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session!.id, base.id);
    expect(ctrl2.session!.interpretation, isNull);
    expect(ctrl2.session!.interpretationResultMode, isNull);
    expect(ctrl2.session!.drawnCards.map((c) => c.card.id).toList(), ids);

    final second = await world.completeViaController(ctrl2, interp2);
    expect(second!.deliveryKind, TarotReadingDeliveryKind.safety);
    expect(second.isJournalEligible, isFalse);
    expect(ai.callCount, 0);
    expect(ai2.callCount, 0);
    expect(world.charge.alreadyCharged(base.id), isFalse);
    expect(world.authority.balance, 100);
    ctrl2.dispose();
  });
}
