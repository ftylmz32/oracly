/// Phase 9 — pause/resume lifecycle around draw + restore checkpoints.
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

  test('draw then simulated pause/resume via restoreActiveSession', () async {
    final (storage, repo, _) = await bootRepo();
    var ctrl = await _ready(repo);
    final drawn = await ctrl.drawCard();
    await ctrl.flush();
    final sid = ctrl.session!.id;
    final cardId = drawn.card.id;
    ctrl.dispose();

    // Simulated app pause — new controller restore checkpoint.
    final ctrl2 = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session!.id, sid);
    expect(ctrl2.session!.drawnCards, hasLength(1));
    expect(ctrl2.session!.drawnCards.first.card.id, cardId);
    assertSessionDeckConsistent(ctrl2);

    await ctrl2.advanceAfterReveal();
    await ctrl2.drawCard();
    assertNoDuplicateCards(ctrl2.session!);
    assertDrawWithinSpread(ctrl2.session!);
    ctrl2.dispose();
  });

  test('pause mid delayed draw — restore has consistent cards or empty',
      () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    repo.delaySaves = const Duration(milliseconds: 80);
    final pending = ctrl.drawCard();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // Simulate kill before await — dispose controller, wait pending.
    ctrl.dispose();
    try {
      await pending;
    } catch (_) {}

    final ctrl2 = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    await ctrl2.restoreActiveSession();
    final s = ctrl2.session;
    if (s != null) {
      assertDrawWithinSpread(s);
      expect(s.drawnCards.length, anyOf(0, 1));
    }
    ctrl2.dispose();
  });

  test('reading checkpoint restore after full draw', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    for (var i = 0; i < 3; i++) {
      await ctrl.drawCard();
      if (i < 2) await ctrl.advanceAfterReveal();
    }
    expect(ctrl.session!.drawnCards, hasLength(3));
    final ids = ctrl.session!.drawnCards.map((c) => c.card.id).toList();
    await ctrl.flush();
    ctrl.dispose();

    final ctrl2 = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    await ctrl2.restoreActiveSession();
    expect(ctrl2.session!.drawnCards.map((c) => c.card.id).toList(), ids);
    assertNoDuplicateCards(ctrl2.session!);
    ctrl2.dispose();
  });
}
