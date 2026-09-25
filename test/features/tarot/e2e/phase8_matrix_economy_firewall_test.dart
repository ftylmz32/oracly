/// Phase 8 — remaining economy recovery / navigate-away / firewalls.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('insufficient gems then top-up — retry one charge no redraw', () async {
    final world = await TarotE2eWorld.create(gems: 0);
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_gems_recover');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final ids = ctrl.session!.drawnCards.map((c) => c.card.id).toList();
    expect(await world.completeViaController(ctrl, interp), isNull);
    expect(ai.callCount, 0);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    world.authority.balance = 100;
    await world.wallet.refresh();
    final ok = await world.completeViaController(ctrl, interp);
    expect(ok, isNotNull);
    expect(ai.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(ctrl.session!.drawnCards.map((c) => c.card.id).toList(), ids);
    ctrl.dispose();
  });

  test('navigate away shouldCommit false — reopen charges once', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_nav_away');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    expect(
      await world.completeViaController(
        ctrl,
        interp,
        shouldCommit: () => false,
      ),
      isNull,
    );
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(await world.completeViaController(ctrl, interp), isNotNull);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, 80);
    ctrl.dispose();
  });

  test('zero-gem safety still free', () async {
    final world = await TarotE2eWorld.create(gems: 0);
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final base = threeContrastSession(id: 'e2e_zero_safety');
    final session = ReadingSession(
      id: base.id,
      deckId: base.deckId,
      spread: base.spread,
      intention: const TarotIntention(text: 'Intihar etmeyi düşünüyorum'),
      shuffleSeed: base.shuffleSeed,
      startedAt: base.startedAt,
      drawnCards: base.drawnCards,
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reading,
    );
    final content = await world.completePaid(session, interp);
    expect(content, isNotNull);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.safety);
    expect(ai.callCount, 0);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, 0);
  });

  test('public spread firewall — crossroads/seven/celtic excluded', () {
    final publicIds = TarotTableSpreadOverlay.options.toSet();
    expect(publicIds.contains(TarotSpreadType.crossroads), isFalse);
    expect(publicIds.contains(TarotSpreadType.sevenCard), isFalse);
    expect(publicIds.contains(TarotSpreadType.celticCross), isFalse);
    expect(publicIds.contains(TarotSpreadType.single), isTrue);
    expect(publicIds.contains(TarotSpreadType.threeCard), isTrue);
    expect(publicIds.contains(TarotSpreadType.fiveCard), isTrue);
    expect(
      NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.crossroads),
      isFalse,
    );
    expect(
      ReadingResultModeResolver.of(TarotSpreadType.crossroads),
      ReadingResultMode.legacy,
    );
  });
}
