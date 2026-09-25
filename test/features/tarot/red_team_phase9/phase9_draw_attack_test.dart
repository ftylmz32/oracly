/// Phase 9.1 — draw lifecycle ownership / abandon race remediation proofs.
/// REAL PROVIDER CALLS = 0.
///
/// Remediated:
/// P1-A: fail-before-write + loadActive throw → local snapshot restored first
/// P1-B: abandon waits for in-flight draw quiesce then clears (no resurrection)
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

import '../e2e/phase8_failing_repo.dart';
import 'phase9_invariants.dart';
import 'phase9_support.dart';

Future<TarotReadingController> _ready(
  Phase8FailingRepo repo, {
  TarotSpreadType spread = TarotSpreadType.threeCard,
}) async {
  final ctrl = TarotReadingController(repository: repo);
  await ctrl.beginSession(spread: spread, deckId: 'classic');
  await ctrl.advanceToShuffle();
  await ctrl.performShuffle();
  await ctrl.finishShuffle();
  return ctrl;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('P1-A: read-back throw restores local session+deck; second draw blocked',
      () async {
    final (_, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final before = ctrl.deckController.remaining;
    final top = ctrl.deckController.drawPile.last.id;
    final fanBefore =
        ctrl.deckController.fanCards.map((c) => c.id).toList();
    repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
    repo.failNextLoadActive = true;
    await expectLater(ctrl.drawCard(), throwsA(isA<StateError>()));
    expect(ctrl.drawStateUncertain, isTrue);
    expect(ctrl.session!.drawnCards, isEmpty);
    expect(ctrl.deckController.remaining, before);
    expect(ctrl.deckController.drawPile.last.id, top);
    expect(
      ctrl.deckController.fanCards.map((c) => c.id).toList(),
      fanBefore,
    );
    await expectLater(ctrl.drawCard(), throwsA(isA<StateError>()));
    ctrl.dispose();
  });

  test('P1-A escape: uncertain → abandon → new session', () async {
    final (_, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
    repo.failNextLoadActive = true;
    await expectLater(ctrl.drawCard(), throwsA(isA<StateError>()));
    expect(ctrl.drawStateUncertain, isTrue);
    await ctrl.abandonActiveForNewStart();
    expect(ctrl.session, isNull);
    expect(ctrl.drawStateUncertain, isFalse);
    await ctrl.beginSession(spread: TarotSpreadType.threeCard, deckId: 'classic');
    await ctrl.advanceToShuffle();
    await ctrl.performShuffle();
    await ctrl.finishShuffle();
    final drawn = await ctrl.drawCard();
    expect(drawn.card.id, isNotNull);
    expect(ctrl.session!.drawnCards, hasLength(1));
    ctrl.dispose();
  });

  test('write-then-throw reconciles commit (8.3 firewall)', () async {
    final (_, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    repo.faultQueue.add(Phase8SaveFault.writeThenThrow);
    final drawn = await ctrl.drawCard();
    expect(ctrl.session!.drawnCards, hasLength(1));
    expect(ctrl.session!.drawnCards.first.card.id, drawn.card.id);
    assertSessionDeckConsistent(ctrl);
    final durable = await repo.loadActiveSession();
    expect(durable!.drawnCards, hasLength(1));
    ctrl.dispose();
  });

  test('P1-B: abandon waits for pending save; no resurrection', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;

    final pending = ctrl.drawCard();
    await started.future;

    var abandonDone = false;
    final abandon = ctrl.abandonActiveForNewStart().then((_) {
      abandonDone = true;
    });
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(abandonDone, isFalse, reason: 'abandon must wait for draw quiesce');

    gate.complete();
    try {
      await pending;
    } catch (_) {}
    await abandon;
    expect(ctrl.session, isNull);
    expect(ctrl.drawStateUncertain, isFalse);

    final durable =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(durable, isNull);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    final still =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(still, isNull, reason: 'no late resurrection');
    ctrl.dispose();
  });

  test('beginSession waits behind stale save; final active is new', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final oldId = ctrl.session!.id;
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;

    final pending = ctrl.drawCard();
    await started.future;

    final begin = ctrl.beginSession(
      spread: TarotSpreadType.single,
      deckId: 'classic',
    );
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    try {
      await pending;
    } catch (_) {}
    final next = await begin;
    expect(next.id, isNot(oldId));
    final durable =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(durable!.id, next.id);
    expect(durable.drawnCards, isEmpty);
    ctrl.dispose();
  });

  test('rapid double abandon during pending save — final null', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;

    final pending = ctrl.drawCard();
    await started.future;
    final a1 = ctrl.abandonActiveForNewStart();
    final a2 = ctrl.abandonActiveForNewStart();
    gate.complete();
    try {
      await pending;
    } catch (_) {}
    await Future.wait([a1, a2]);
    expect(ctrl.session, isNull);
    final durable =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(durable, isNull);
    ctrl.dispose();
  });

  test('drawAllRemaining abandon — no batch resurrection', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo, spread: TarotSpreadType.fiveCard);
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;

    final pending = ctrl.drawAllRemaining();
    await started.future;
    final abandon = ctrl.abandonActiveForNewStart();
    gate.complete();
    try {
      await pending;
    } catch (_) {}
    await abandon;
    expect(ctrl.session, isNull);
    final durable =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(durable, isNull);
    ctrl.dispose();
  });

  test('fan draw abandon — no stale fan commit', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;

    final pending = ctrl.drawCard(fanIndex: 0);
    await started.future;
    final abandon = ctrl.abandonActiveForNewStart();
    gate.complete();
    try {
      await pending;
    } catch (_) {}
    await abandon;
    expect(ctrl.session, isNull);
    final durable =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(durable, isNull);
    ctrl.dispose();
  });

  test('resetSession invalidates stale local commit', () async {
    final (storage, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;

    final pending = ctrl.drawCard();
    await started.future;
    ctrl.resetSession();
    expect(ctrl.session, isNull);
    expect(ctrl.drawStateUncertain, isFalse);
    gate.complete();
    try {
      await pending;
    } catch (_) {}
    expect(ctrl.session, isNull, reason: 'stale must not reassign session');

    await ctrl.abandonActiveForNewStart();
    final durable =
        await TarotReadingRepositoryImpl.fromStorage(storage).loadActiveSession();
    expect(durable, isNull);
    ctrl.dispose();
  });

  test('fan write-then-throw reconciles; drawAllRemaining fail rolls back',
      () async {
    final (_, repo, _) = await bootRepo();
    final ctrl = await _ready(repo, spread: TarotSpreadType.fiveCard);
    repo.faultQueue.add(Phase8SaveFault.writeThenThrow);
    final fanDrawn = await ctrl.drawCard(fanIndex: 0);
    expect(ctrl.session!.drawnCards.single.card.id, fanDrawn.card.id);
    await ctrl.advanceAfterReveal();
    await ctrl.drawCard();
    await ctrl.advanceAfterReveal();
    expect(ctrl.session!.drawnCards, hasLength(2));
    final ids2 = ctrl.session!.drawnCards.map((c) => c.card.id).toList();
    final deckN = ctrl.deckController.remaining;
    repo.faultQueue.add(Phase8SaveFault.failBeforeWrite);
    await expectLater(ctrl.drawAllRemaining(), throwsA(isA<StateError>()));
    expect(ctrl.session!.drawnCards.map((c) => c.card.id).toList(), ids2);
    expect(ctrl.deckController.remaining, deckN);
    assertNoDuplicateCards(ctrl.session!);
    ctrl.dispose();
  });

  test('dispose while save pending — no crash', () async {
    final (_, repo, _) = await bootRepo();
    final ctrl = await _ready(repo);
    final started = Completer<void>();
    final gate = Completer<void>();
    repo.saveStarted = started;
    repo.saveGate = gate;
    final pending = ctrl.drawCard();
    await started.future;
    ctrl.dispose();
    gate.complete();
    try {
      await pending;
    } catch (_) {}
  });
}
