/// Phase 8 — recovery authorization + RESTART A (empty draw).
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RESTART A — session created, no cards: restore + null load', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.beginSession(
      spread: TarotSpreadType.threeCard,
      deckId: 'classic',
    );
    expect(ctrl.session!.drawnCards, isEmpty);
    await ctrl.flush();
    ctrl.dispose();

    final second = world.interpretation(ai, world.newCache());
    final ctrl2 = world.controller(second);
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session, isNotNull);
    expect(ctrl2.session!.drawnCards, isEmpty);
    expect(await world.completeViaController(ctrl2, second), isNull);
    expect(ai.callCount, 0);
    ctrl2.dispose();
  });

  test('already charged + throw → emergencyFallback recovery', () async {
    final world = await TarotE2eWorld.create();
    final firstAi = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final firstInterp = world.interpretation(firstAi, world.newCache());
    final firstCtrl = world.controller(firstInterp);
    final session = threeContrastSession(id: 'e2e_recover_paid');
    await firstCtrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(firstCtrl, firstInterp);
    final wallet = world.authority.balance;
    // Clear body so CASE A throws → emergencyFallback (not 8.1 replay).
    await firstCtrl.updateSession(
      ReadingSession(
        id: session.id,
        deckId: session.deckId,
        spread: session.spread,
        intention: session.intention,
        shuffleSeed: session.shuffleSeed,
        startedAt: session.startedAt,
        drawnCards: session.drawnCards,
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await firstCtrl.flush();
    firstCtrl.dispose();

    final throwAi = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
      AiOutcome.failure(AiFailure.network()),
    ]);
    final second = world.interpretation(throwAi, world.newCache());
    final ctrl2 = world.controller(second);
    await ctrl2.restoreActiveSession();
    final recovered = await world.completeViaController(ctrl2, second);
    expect(recovered, isNotNull);
    expect(recovered!.deliveryKind, TarotReadingDeliveryKind.recovery);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, wallet);
    ctrl2.dispose();
  });

  test('unpaid recovery delivery rejected — charge=0', () async {
    final world = await TarotE2eWorld.create();
    final before = world.authority.balance;
    final session = threeContrastSession(id: 'e2e_recover_unpaid');
    final interp = world.interpretation(
      ScriptedNarrativeAi([AiOutcome.failure(AiFailure.network())]),
      world.newCache(),
    );
    final content = await TarotReadingCompletion(
      charge: world.charge,
      interpretation: interp,
    ).complete(
      session,
      load: () async => interp.emergencyFallback(
        session,
        reason: 'unauthorized recovery probe',
      ),
    );
    expect(content, isNull);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, before);
  });
}
