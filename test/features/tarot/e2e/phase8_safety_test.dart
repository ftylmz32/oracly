/// Phase 8 — sensitive intention: free safety, no provider / charge / journal.
/// REAL PROVIDER CALLS = 0.
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

  test('self-harm intention — provider=0 charge=0 no envelope', () async {
    final world = await TarotE2eWorld.create();
    final before = world.authority.balance;
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final base = threeContrastSession(id: 'e2e_safety');
    await ctrl.updateSession(
      ReadingSession(
        id: base.id,
        deckId: base.deckId,
        spread: base.spread,
        intention: const TarotIntention(
          text: 'Intihar etmeyi düşünüyorum',
        ),
        shuffleSeed: base.shuffleSeed,
        startedAt: base.startedAt,
        drawnCards: base.drawnCards,
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );

    final content = await world.completeViaController(ctrl, interp);
    expect(content, isNotNull);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.safety);
    expect(content.isJournalEligible, isFalse);
    expect(ai.callCount, 0);
    expect(world.charge.alreadyCharged(base.id), isFalse);
    expect(world.authority.balance, before);
    expect(ctrl.session!.interpretation, isNull);
    expect(ctrl.session!.interpretationResultMode, isNull);
    expect(ctrl.session!.interpretationSource, isNull);
    expect(ctrl.session!.interpretationDeliveryKind, isNull);
    ctrl.dispose();
  });
}
