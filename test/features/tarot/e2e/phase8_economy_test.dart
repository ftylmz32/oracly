/// Phase 8 — economy / attempt / insufficient-gems / quality-fail proofs.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('insufficient gems — provider=0 charge=0 cards intact', () async {
    final world = await TarotE2eWorld.create(gems: 0);
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final session = threeContrastSession(id: 'e2e_no_gems');
    final content = await world.completePaid(session, interp);
    expect(content, isNull);
    expect(ai.callCount, 0);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, 0);
    expect(session.drawnCards.length, 3);
  });

  test('quality fail then pass — provider=2 charge=1 same session', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured(callIndex: 3)),
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final session = threeContrastSession(id: 'e2e_qf_pass');
    final content = await world.completePaid(session, interp);
    expect(content, isNotNull);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(ai.callCount, 2);
    expect(ai.attempts, [1, 2]);
    expect(world.charge.alreadyCharged(session.id), isTrue);
  });

  test('both quality attempts fail — charge=0 no success UI', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured(callIndex: 3)),
      AiOutcome.success(qualityFailStructured(callIndex: 3)),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final session = threeContrastSession(id: 'e2e_qf_both');
    final content = await world.completePaid(session, interp);
    expect(content, isNull);
    expect(ai.callCount, 2);
    expect(world.charge.alreadyCharged(session.id), isFalse);
  });

  test('provider throw before charge — wallet unchanged', () async {
    final world = await TarotE2eWorld.create();
    final before = world.authority.balance;
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.network()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final session = threeContrastSession(id: 'e2e_provider_fail');
    final content = await world.completePaid(session, interp);
    expect(content, isNull);
    expect(ai.callCount, 2); // Narrative max attempts = 2
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, before);
  });
}
