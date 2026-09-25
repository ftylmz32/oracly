/// Phase 8.3 — transactional draw persist / ghost-draw proof.
/// REAL PROVIDER CALLS = 0. Settle / 8.1 replay untouched.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'phase8_failing_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase8FailingRepo repo;
  late LocalStorage storage;
  late TarotReadingController reading;

  Future<void> boot(TarotSpreadType spread) async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    storage = LocalStorage(await SharedPreferences.getInstance());
    repo = Phase8FailingRepo(TarotReadingRepositoryImpl.fromStorage(storage));
    reading = TarotReadingController(repository: repo);
    await reading.beginSession(spread: spread, deckId: 'classic');
    await reading.advanceToShuffle();
    await reading.performShuffle();
    await reading.finishShuffle();
  }

  Future<TarotReadingController> restartController() async {
    reading.dispose();
    final next = TarotReadingController(
      repository: Phase8FailingRepo(
        TarotReadingRepositoryImpl.fromStorage(storage),
      ),
    );
    await next.restoreActiveSession();
    return next;
  }

  tearDown(() {
    reading.dispose();
  });

  test('fail-before-write — no ghost; retry same card; restart empty',
      () async {
    await boot(TarotSpreadType.threeCard);
    final beforeDeck = reading.deckController.remaining;
    final tentative = reading.deckController.drawPile.last;
    repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
    await expectLater(reading.drawCard(), throwsA(isA<StateError>()));
    expect(reading.session!.drawnCards, isEmpty);
    expect(reading.deckController.remaining, beforeDeck);
    expect(reading.deckController.drawPile.last.id, tentative.id);
    final durable = await repo.loadActiveSession();
    expect(durable!.drawnCards, isEmpty);
    reading = await restartController();
    expect(reading.session!.drawnCards, isEmpty);
    final drawn = await reading.drawCard();
    expect(drawn.card.id, tentative.id);
    expect(reading.session!.drawnCards, hasLength(1));
  });

  test('write-then-throw — reconcile commit; restart sees card', () async {
    await boot(TarotSpreadType.threeCard);
    repo.faultQueue.add(Phase8SaveFault.writeThenThrow);
    final drawn = await reading.drawCard();
    expect(reading.session!.drawnCards, hasLength(1));
    expect(reading.session!.drawnCards.first.card.id, drawn.card.id);
    final durable = await repo.loadActiveSession();
    expect(durable!.drawnCards, hasLength(1));
    expect(durable.drawnCards.first.card.id, drawn.card.id);
    reading = await restartController();
    expect(reading.session!.drawnCards, hasLength(1));
    expect(reading.session!.drawnCards.first.card.id, drawn.card.id);
  });

  test('fan fail-before-write — fan order restored; same index card', () async {
    await boot(TarotSpreadType.threeCard);
    final fanBefore =
        reading.deckController.fanCards.map((c) => c.id).toList();
    final expected = fanBefore[1];
    repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
    await expectLater(
      reading.drawCard(fanIndex: 1),
      throwsA(isA<StateError>()),
    );
    final fanAfter =
        reading.deckController.fanCards.map((c) => c.id).toList();
    expect(fanAfter, fanBefore);
    expect(reading.session!.drawnCards, isEmpty);
    final drawn = await reading.drawCard(fanIndex: 1);
    expect(drawn.card.id, expected);
  });

  test('drawAllRemaining fail — batch rolls back; retry deterministic',
      () async {
    await boot(TarotSpreadType.fiveCard);
    await reading.drawCard();
    await reading.advanceAfterReveal();
    await reading.drawCard();
    await reading.advanceAfterReveal();
    expect(reading.session!.drawnCards, hasLength(2));
    final ids2 =
        reading.session!.drawnCards.map((c) => c.card.id).toList();
    final deckBefore = reading.deckController.remaining;
    repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
    await expectLater(
      reading.drawAllRemaining(),
      throwsA(isA<StateError>()),
    );
    expect(reading.session!.drawnCards, hasLength(2));
    expect(
      reading.session!.drawnCards.map((c) => c.card.id).toList(),
      ids2,
    );
    expect(reading.deckController.remaining, deckBefore);
    reading = await restartController();
    expect(reading.session!.drawnCards, hasLength(2));
    await reading.drawAllRemaining();
    expect(reading.session!.drawnCards, hasLength(5));
    final ids = reading.session!.drawnCards.map((c) => c.card.id).toSet();
    expect(ids, hasLength(5));
  });

  test('draw lock — concurrent draw rejected while locked', () async {
    await boot(TarotSpreadType.threeCard);
    repo.delaySaves = const Duration(milliseconds: 40);
    final a = reading.drawCard();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await expectLater(reading.drawCard(), throwsA(isA<StateError>()));
    await a;
    expect(reading.session!.drawnCards, hasLength(1));
  });
}
