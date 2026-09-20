/// Deterministic concurrency proof for Tarot journal persist coalescing.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/services/journal_persist_gate.dart';

void main() {
  test('concurrent callers share one persist job and one note offer', () async {
    final gate = JournalPersistGate();
    final started = Completer<void>();
    final release = Completer<void>();
    var saveCalls = 0;
    var analyticsCalls = 0;
    var versionSeeds = 0;
    var noteOffers = 0;
    var historyCount = 0;

    Future<void> body() async {
      started.complete();
      await release.future;
      saveCalls++;
      analyticsCalls++;
      versionSeeds++;
      historyCount = 1;
      gate.completed = true;
    }

    final first = gate.run(body: body, offerNote: false);
    await started.future;

    final second = gate.run(
      body: body,
      offerNote: true,
      onOfferNote: () async {
        noteOffers++;
      },
    );

    release.complete();
    await Future.wait([first, second]);

    expect(saveCalls, 1);
    expect(analyticsCalls, 1);
    expect(versionSeeds, 1);
    expect(historyCount, 1);
    expect(noteOffers, 1);
    expect(gate.completed, isTrue);
  });

  test('shared failure does not complete; later retry starts a new job',
      () async {
    final gate = JournalPersistGate();
    final started = Completer<void>();
    final release = Completer<void>();
    var saveCalls = 0;

    Future<void> failingBody() async {
      started.complete();
      await release.future;
      saveCalls++;
      throw StateError('persist failed');
    }

    final first = gate.run(body: failingBody);
    await started.future;
    final second = gate.run(body: failingBody, offerNote: true);
    release.complete();
    await Future.wait([
      first.catchError((_) {}),
      second.catchError((_) {}),
    ]);

    // Body catches are inside ReadingScreen; here the gate awaits a throwing
    // body. Mirror screen by catching in the body itself:
    expect(gate.completed, isFalse);
    expect(saveCalls, 1);

    await gate.run(
      body: () async {
        saveCalls++;
        gate.completed = true;
      },
    );
    expect(saveCalls, 2);
    expect(gate.completed, isTrue);
  });

  test('failure-contained body: concurrent waiters do not start a second save',
      () async {
    final gate = JournalPersistGate();
    final started = Completer<void>();
    final release = Completer<void>();
    var saveCalls = 0;

    Future<void> body() async {
      started.complete();
      await release.future;
      saveCalls++;
      // Screen catches — completed stays false.
    }

    final a = gate.run(body: body);
    await started.future;
    final b = gate.run(body: body);
    release.complete();
    await Future.wait([a, b]);

    expect(saveCalls, 1);
    expect(gate.completed, isFalse);

    await gate.run(
      body: () async {
        saveCalls++;
        gate.completed = true;
      },
    );
    expect(saveCalls, 2);
  });
}
