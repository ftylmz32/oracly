/// Phase 9 — JournalPersistGate coalescing / hang / fail-after-write.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/domain/repositories/user_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/services/journal_persist_gate.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';

class _MemHistory implements HistoryRepository {
  final List<ReadingModel> readings = [];
  @override
  Future<List<ReadingModel>> getReadings() async => List.of(readings);
  @override
  Future<void> saveReading(ReadingModel reading) async {
    readings.removeWhere((r) => r.id == reading.id);
    readings.add(reading);
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

  test('auto+manual+favorite coalesce — one durable write', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_jgate');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    final completed = await ctrl.completeSession();
    final history = _MemHistory();
    final service = ReadingService(history, _StubUser());
    final gate = JournalPersistGate();
    final started = Completer<void>();
    final release = Completer<void>();
    var saves = 0;
    var notes = 0;

    Future<void> body() async {
      started.complete();
      await release.future;
      saves++;
      await service.saveFromSession(
        session: completed,
        aiSummary: live!.fullInterpretation!,
        resultMode: 'narrativeV2',
        interpretationSource: live.interpretationSource.name,
        deliveryKind: live.deliveryKind.name,
      );
      gate.completed = true;
    }

    final auto = gate.run(body: body);
    await started.future;
    final manual = gate.run(body: body, offerNote: true, onOfferNote: () async {
      notes++;
    });
    final fav = gate.run(body: body, offerNote: true);
    release.complete();
    await Future.wait([auto, manual, fav]);
    expect(saves, 1);
    expect(history.readings, hasLength(1));
    expect(notes, 1);
    expect(ai.callCount, 1);
    ctrl.dispose();
  });

  test('hang then callers await — fail after write leaves retryable', () async {
    final gate = JournalPersistGate();
    final started = Completer<void>();
    final release = Completer<void>();
    var attempts = 0;

    final first = gate.run(body: () async {
      started.complete();
      await release.future;
      attempts++;
      // Fail after "write" — completed stays false.
    });
    await started.future;
    final waiter = gate.run(body: () async {
      attempts++;
      gate.completed = true;
    });
    release.complete();
    await first;
    expect(gate.completed, isFalse);
    await gate.run(body: () async {
      attempts++;
      gate.completed = true;
    });
    await waiter;
    expect(gate.completed, isTrue);
    expect(attempts, greaterThanOrEqualTo(2));
  });
}
