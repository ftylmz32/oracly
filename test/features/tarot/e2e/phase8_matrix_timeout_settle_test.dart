/// Phase 8 — timeout + charge-commit failure after usable content.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TIMEOUT — short timeout charge 0; retry one charge', () async {
    final world = await TarotE2eWorld.create();
    final session = threeContrastSession(id: 'e2e_timeout');
    final completion = TarotReadingCompletion(charge: world.charge);
    final abandoned = await completion.complete(
      session,
      timeout: const Duration(milliseconds: 40),
      load: () => Future<AiReadingContent>.delayed(
        const Duration(seconds: 3),
        () => throw StateError('slow provider must not finish'),
      ),
    );
    expect(abandoned, isNull);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, 100);

    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final ok = await world.completePaid(
      session,
      world.interpretation(ai, world.newCache()),
    );
    expect(ok, isNotNull);
    expect(ai.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, 80);
  });

  test('CHARGE COMMIT FAILURE — usable then settle fail; safe retry', () async {
    final world = await TarotE2eWorld.create();
    final session = threeContrastSession(id: 'e2e_settle_fail');
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final completion = TarotReadingCompletion(
      charge: world.charge,
      interpretation: interp,
    );
    final failed = await completion.complete(
      session,
      load: () async {
        final content = await interp.generateContent(session, language: 'en');
        world.authority.online = false;
        return content;
      },
    );
    expect(failed, isNull);
    expect(world.charge.alreadyCharged(session.id), isFalse);
    expect(world.authority.balance, 100);
    expect(session.drawnCards, hasLength(3));

    world.authority.online = true;
    final retry = await world.completePaid(session, interp);
    expect(retry, isNotNull);
    expect(retry!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(session.id, 'e2e_settle_fail');
    expect(world.authority.balance, 80);
  });
}
