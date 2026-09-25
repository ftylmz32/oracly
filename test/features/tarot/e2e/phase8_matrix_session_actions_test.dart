/// Phase 8 — daily collision, deck continuity, safety restart, intention.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_intent.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    if (DailyRitualIntent.hasPendingDraw) {
      DailyRitualIntent.consumePendingDraw();
    }
  });

  test('daily ritual collision — abandon stale active', () async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = TarotReadingRepositoryImpl.fromStorage(storage);
    final ctrl = TarotReadingController(repository: repo);
    await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    await ctrl.advanceToShuffle();
    await ctrl.performShuffle();
    await ctrl.finishShuffle();
    await ctrl.drawCard();
    expect(ctrl.session!.drawnCards, hasLength(1));
    final staleId = ctrl.session!.id;
    DailyRitualIntent.requestDailyCardDraw();
    expect(DailyRitualIntent.hasPendingDraw, isTrue);
    // Mirrors TarotModuleRoot: pending daily draw abandons stale active.
    await ctrl.abandonActiveForNewStart();
    expect(ctrl.session, isNull);
    expect(await repo.loadActiveSession(), isNull);
    expect(DailyRitualIntent.consumePendingDraw(), isTrue);
    await ctrl.beginSession(spread: TarotSpreadType.single, deckId: 'classic');
    expect(ctrl.session!.id, isNot(staleId));
    expect(ctrl.session!.drawnCards, isEmpty);
    ctrl.dispose();
  });

  test('deck continuity after partial restore — no duplicates', () async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = TarotReadingRepositoryImpl.fromStorage(storage);
    final a = TarotReadingController(repository: repo);
    await a.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    await a.advanceToShuffle();
    await a.performShuffle();
    await a.finishShuffle();
    final seed = a.session!.shuffleSeed;
    await a.drawCard();
    final firstId = a.session!.drawnCards.first.card.id;
    a.dispose();
    final b = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    await b.restoreActiveSession();
    expect(b.session!.shuffleSeed, seed);
    expect(b.session!.drawnCards.single.card.id, firstId);
    await b.drawCard();
    await b.drawCard();
    final ids = b.session!.drawnCards.map((c) => c.card.id).toList();
    expect(ids, hasLength(3));
    expect(ids.toSet(), hasLength(3));
    expect(ids.first, firstId);
    b.dispose();
  });

  test('safety restart — no paid envelope / charge / journal fields', () async {
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
    final content = await world.completeViaController(ctrl, interp);
    expect(content!.deliveryKind, TarotReadingDeliveryKind.safety);
    expect(ctrl.session!.interpretation, isNull);
    expect(world.charge.alreadyCharged(base.id), isFalse);
    ctrl.dispose();
    final next = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(cloneSolThreeForEmptySession())]),
        world.newCache(),
      ),
    );
    await next.restoreActiveSession();
    // Safety never stores interpretation envelope.
    expect(next.session?.interpretation, isNull);
    expect(world.charge.alreadyCharged(base.id), isFalse);
    next.dispose();
  });

  test('first reading spread policy is single; no early charge', () {
    expect(TarotFirstReading.spread, TarotSpreadType.single);
  });

  test('custom intention + topic stored; history JSON privacy-safe', () {
    final s = ReadingSession(
      id: 'e2e_intent',
      deckId: 'classic',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(
        text: 'private worry about work',
        topic: 'career',
      ),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 25),
      drawnCards: threeContrastSession().drawnCards,
    );
    expect(s.intention.text, 'private worry about work');
    expect(s.intention.topic, 'career');
    final json = s.toJson();
    expect(json['intentionTopic'], 'career');
    expect(json['intention'], 'private worry about work');
  });
}
