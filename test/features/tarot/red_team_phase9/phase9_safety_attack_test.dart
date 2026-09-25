/// Phase 9 — adversarial safety string / race / stale replay attacks.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/safety/sensitive_topic_gate.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';

ReadingSession _crisis(String text, {String id = 'p9_safe'}) {
  final b = threeContrastSession(id: id);
  return ReadingSession(
    id: b.id,
    deckId: b.deckId,
    spread: b.spread,
    intention: TarotIntention(text: text),
    shuffleSeed: b.shuffleSeed,
    startedAt: b.startedAt,
    drawnCards: b.drawnCards,
    status: ReadingSessionStatus.inProgress,
    flowStep: ReadingFlowStep.reading,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adversarial crisis strings — case/whitespace/punct/TR', () {
    const variants = [
      'Intihar etmeyi düşünüyorum',
      '  İNTİHAR etmeyi düşünüyorum  ',
      'intihar!!!',
      'Kill Myself',
      'want to die...',
      'kendimi öldürmek istiyorum',
    ];
    for (final v in variants) {
      expect(SensitiveTopicGate.maybeRespond(v), isNotNull, reason: v);
    }
  });

  test('safety race retries — still free, provider=0', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    await ctrl.updateSession(_crisis('Intihar etmeyi düşünüyorum'));
    final results = await Future.wait([
      world.completeViaController(ctrl, interp),
      world.completeViaController(ctrl, interp),
      world.completeViaController(ctrl, interp),
    ]);
    for (final r in results) {
      expect(r!.deliveryKind, TarotReadingDeliveryKind.safety);
      expect(r.isJournalEligible, isFalse);
    }
    expect(ai.callCount, 0);
    expect(world.charge.alreadyCharged(ctrl.session!.id), isFalse);
    ctrl.dispose();
  });

  test('stale paid replay + new sensitive intention — safety wins', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final base = threeContrastSession(id: 'p9_stale_safe');
    await ctrl.updateSession(
      base.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
        interpretation: '## Summary\nprior paid body',
        interpretationResultMode: 'narrativeV2',
        interpretationSource: 'ai',
        interpretationDeliveryKind: 'interpretation',
      ),
    );
    await world.charge.commit(base.id, spread: TarotSpreadType.threeCard);
    // copyWith cannot change intention — rebuild session.
    final sensitive = ReadingSession(
      id: ctrl.session!.id,
      deckId: ctrl.session!.deckId,
      spread: ctrl.session!.spread,
      intention: const TarotIntention(text: 'Intihar etmeyi düşünüyorum'),
      shuffleSeed: ctrl.session!.shuffleSeed,
      startedAt: ctrl.session!.startedAt,
      drawnCards: ctrl.session!.drawnCards,
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reading,
      interpretation: ctrl.session!.interpretation,
      interpretationResultMode: ctrl.session!.interpretationResultMode,
      interpretationSource: ctrl.session!.interpretationSource,
      interpretationDeliveryKind: ctrl.session!.interpretationDeliveryKind,
    );
    await ctrl.updateSession(sensitive);
    final content = await ctrl.resolveInterpretationContent(forceRefresh: true);
    expect(content.isSafetyResponse, isTrue);
    expect(ctrl.session!.interpretation, '## Summary\nprior paid body');
    expect(ai.callCount, 0);
    ctrl.dispose();
  });
}
