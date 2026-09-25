/// Phase 8 — daily ritual collision / OR / share / favorite.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/domain/repositories/user_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_intent.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_sanitize.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moment_factory.dart';
import 'package:oracly_new/features/favorite_moments/services/favorite_moments_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

class _MemHistory implements HistoryRepository {
  final List<ReadingModel> readings = [];
  @override
  Future<List<ReadingModel>> getReadings() async => List.of(readings);
  @override
  Future<void> saveReading(ReadingModel r) async {
    readings.removeWhere((x) => x.id == r.id);
    readings.add(r);
  }

  @override
  Future<void> deleteReading(String id) async {
    readings.removeWhere((r) => r.id == id || r.sessionId == id);
  }

  @override
  Future<void> clearAll() async => readings.clear();
}

class _StubUser implements UserRepository {
  @override
  Future<void> ensureReadingCompletionMigration(List<String> ids) async {}
  @override
  Future<bool> recordReadingCompletion(String readingId) async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    while (DailyRitualIntent.hasPendingDraw) {
      DailyRitualIntent.consumePendingDraw();
    }
  });

  test('DAILY RITUAL — pending draw abandons stale active', () async {
    final world = await TarotE2eWorld.create();
    final ctrl = world.controller(
      world.interpretation(
        ScriptedNarrativeAi([AiOutcome.success(cloneSolThreeForEmptySession())]),
        world.newCache(),
      ),
    );
    await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    await ctrl.advanceToShuffle();
    await ctrl.performShuffle();
    await ctrl.finishShuffle();
    await ctrl.drawCard();
    expect(ctrl.session!.drawnCards, hasLength(1));
    DailyRitualIntent.requestDailyCardDraw();
    expect(DailyRitualIntent.hasPendingDraw, isTrue);
    // Mirrors TarotModuleRoot._restoreSession pending-draw branch.
    await ctrl.abandonActiveForNewStart();
    expect(DailyRitualIntent.consumePendingDraw(), isTrue);
    expect(ctrl.session, isNull);
    ctrl.dispose();
  });

  test('OR / SHARE / FAVORITE after paid — provider 0 charge 0', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_or_share_fav');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    final paidCalls = ai.callCount;
    final paidBalance = world.authority.balance;
    final completed = await ctrl.completeSession();

    final orCtx = OracleReadingContext.fromSession(
      session: completed,
      content: live!,
    );
    expect(orCtx.sessionId, session.id);
    expect(orCtx.kind, OracleReadingKind.tarot);

    final card = completed.drawnCards.first;
    final share = DiscoveryShareBuilder.tarot(
      theme: live.readingTheme,
      cardName: card.localizedName,
      cardAsset: card.card.image,
      isReversed: card.isReversed,
    );
    expect(DiscoveryShareSanitize.leaksPrivate(share.highlight), isFalse);

    final history = _MemHistory();
    final saved = await ReadingService(history, _StubUser()).saveFromSession(
      session: completed,
      aiSummary: live.fullInterpretation!,
      resultMode: 'narrativeV2',
      interpretationSource: live.interpretationSource.name,
      deliveryKind: live.deliveryKind.name,
    );
    final favs = FavoriteMomentsService(
      LocalFavoriteMomentsRepository(world.storage),
    );
    final draft = FavoriteMomentFactory.tarot(saved!);
    await favs.save(draft);
    await favs.save(draft);
    expect(history.readings, hasLength(1));
    expect(await favs.all(), hasLength(1));
    expect(ai.callCount, paidCalls);
    expect(world.authority.balance, paidBalance);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    ctrl.dispose();
  });
}
