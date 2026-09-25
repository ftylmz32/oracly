/// Phase 9 — property fuzz: 100 sessions, fixed Random(20260925).
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../e2e/phase8_failing_repo.dart';
import 'phase9_invariants.dart';
import 'phase9_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('100 sessions mix single/three/five + faults + restart', () async {
    final rng = Random(20260925);
    final (storage, repo, _) = await bootRepo();
    final spreads = [
      TarotSpreadType.single,
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
    ];

    for (var i = 0; i < 100; i++) {
      final spread = spreads[rng.nextInt(spreads.length)];
      var ctrl = TarotReadingController(repository: repo);
      await ctrl.beginSession(spread: spread, deckId: 'classic');
      await ctrl.advanceToShuffle();
      await ctrl.performShuffle();
      await ctrl.finishShuffle();

      final n = spread.cardCount;
      final failEarly = rng.nextInt(10) == 0;
      if (failEarly) {
        repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
      }
      try {
        for (var d = 0; d < n; d++) {
          await ctrl.drawCard();
          if (d < n - 1) await ctrl.advanceAfterReveal();
        }
      } catch (_) {
        // fail-before-write — session must stay within invariants.
      }
      if (ctrl.session != null) {
        assertDrawWithinSpread(ctrl.session!);
        assertNoDuplicateCards(ctrl.session!);
      }

      // Occasional restart mid-loop.
      if (rng.nextInt(5) == 0) {
        await ctrl.flush();
        final sid = ctrl.session?.id;
        final count = ctrl.session?.drawnCards.length ?? 0;
        ctrl.dispose();
        ctrl = TarotReadingController(
          repository: TarotReadingRepositoryImpl.fromStorage(storage),
        );
        await ctrl.restoreActiveSession();
        if (sid != null && ctrl.session != null) {
          expect(ctrl.session!.id, sid);
          expect(ctrl.session!.drawnCards.length, lessThanOrEqualTo(count + 0));
          assertDrawWithinSpread(ctrl.session!);
        }
      }
      ctrl.dispose();
      // Fresh failing wrapper each iteration keeps fault queue isolated.
      repo.faultQueue.clear();
      repo.failNextSaves = 0;
    }
  });
}
