/// Phase 9 — storage chaos: write-then-throw / fail load / empty history.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../e2e/phase8_failing_repo.dart';
import 'phase9_invariants.dart';
import 'phase9_support.dart';

Future<TarotReadingController> _ready(Phase8FailingRepo repo) async {
  final ctrl = TarotReadingController(repository: repo);
  await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
  await ctrl.advanceToShuffle();
  await ctrl.performShuffle();
  await ctrl.finishShuffle();
  return ctrl;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('write-then-throw on active save — durable draw kept', () async {
    final (_, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    repo.faultQueue.add(Phase8SaveFault.writeThenThrow);
    final drawn = await ctrl.drawCard();
    expect(ctrl.session!.drawnCards.single.card.id, drawn.card.id);
    assertSessionDeckConsistent(ctrl);
    ctrl.dispose();
  });

  test('fail load active — restore throws or null, no crash', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    await ctrl.drawCard();
    await ctrl.flush();
    ctrl.dispose();

    final failing = Phase8FailingRepo(
      TarotReadingRepositoryImpl.fromStorage(storage),
    );
    failing.failNextLoadActive = true;
    final ctrl2 = TarotReadingController(repository: failing);
    await expectLater(ctrl2.restoreActiveSession(), throwsA(isA<StateError>()));
    expect(ctrl2.session, isNull);
    ctrl2.dispose();
  });

  test('empty history load — no invented sessions', () async {
    final (storage, repo, ctrl) = await bootRepo();
    final all = await repo.loadAllSessions();
    final completed = await repo.loadCompletedSessions();
    expect(all, isEmpty);
    expect(completed, isEmpty);
    expect(await repo.loadActiveSession(), isNull);
    expect(storage, isNotNull);
    ctrl.dispose();
  });
}
