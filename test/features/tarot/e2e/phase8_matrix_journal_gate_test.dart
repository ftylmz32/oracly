/// Phase 8 — journal auto+manual race + durable save failure retry.
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
import 'tarot_e2e_harness.dart';

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

  test('JOURNAL race auto+manual — one artifact via JournalPersistGate',
      () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_journal_race');
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
    final manual = gate.run(body: body, offerNote: true);
    release.complete();
    await Future.wait([auto, manual]);
    expect(saves, 1);
    expect(history.readings, hasLength(1));
    expect(ai.callCount, 1);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    ctrl.dispose();
  });

  test('JOURNAL durable fail + retry — provider 0 extra charge 0', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_journal_retry');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    final completed = await ctrl.completeSession();
    final paidCalls = ai.callCount;
    final paidBalance = world.authority.balance;
    final history = _MemHistory();
    final service = ReadingService(history, _StubUser());
    final gate = JournalPersistGate();
    var attempts = 0;

    await gate.run(
      body: () async {
        attempts++;
        // Fail closed — completed stays false (mirrors ReadingScreen catch).
      },
    );
    expect(gate.completed, isFalse);
    expect(history.readings, isEmpty);

    await gate.run(
      body: () async {
        attempts++;
        await service.saveFromSession(
          session: completed,
          aiSummary: live!.fullInterpretation!,
          resultMode: 'narrativeV2',
          interpretationSource: live.interpretationSource.name,
          deliveryKind: live.deliveryKind.name,
        );
        gate.completed = true;
      },
    );
    expect(attempts, 2);
    expect(history.readings, hasLength(1));
    expect(ai.callCount, paidCalls);
    expect(world.authority.balance, paidBalance);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    ctrl.dispose();
  });
}
