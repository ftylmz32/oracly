/// Dream Phase 1.1 — openSaved is fail-closed: nothing about a supplied Dream
/// is visible until the current owner's storage returns it, and an owner
/// change (A→B or A→B→A) during that lookup always fails.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/core/memory/oracly_memory_retriever.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';

import 'dream_phase1_support.dart';

/// Reads the real record immediately, then holds it until [release].
class _HeldLookupRepository implements DreamRepository {
  _HeldLookupRepository(this.inner);

  final DreamRepository inner;
  final _gate = Completer<void>();
  final _entered = Completer<void>();

  Future<void> get entered => _entered.future;
  void release() => _gate.complete();

  @override
  Future<DreamRecord?> getById(String id) async {
    final record = await inner.getById(id);
    if (!_entered.isCompleted) _entered.complete();
    await _gate.future;
    return record;
  }

  @override
  Future<List<DreamRecord>> getAll() => inner.getAll();
  @override
  Future<void> save(DreamRecord record) => inner.save(record);
  @override
  Future<void> delete(String id) => inner.delete(id);
  @override
  Future<void> sync() => inner.sync();
}

void main() {
  late DreamPhase1Env env;
  late _HeldLookupRepository held;
  late DreamAnalysisController controller;
  late Dream stored;
  late List<Dream?> notified;

  setUp(() async {
    env = await DreamPhase1Env.open();
    stored = (await env.service().analyze(narrative: phase1NarrativeA)).dream;
    env.ai.calls = 0;
    held = _HeldLookupRepository(env.repo);
    controller = DreamAnalysisController(
      DreamExperienceService(
        repository: held,
        ai: env.ai,
        owner: DreamOwnerGuard.fromStorage(env.storage),
        versions: env.versions,
        memory: OraclyMemoryRetriever(env.memory),
      ),
    );
    notified = [];
    controller.addListener(() => notified.add(controller.dream));
  });

  tearDown(() => controller.dispose());

  void expectNothingVisible() {
    expect(controller.dream, isNull);
    expect(controller.phase, isNot(DreamJourneyPhase.complete));
    expect(notified.whereType<Dream>(), isEmpty);
  }

  Future<void> expectFailsClosed(Future<void> Function() switchOwner) async {
    final opening = controller.openSaved(stored);
    await held.entered;
    expectNothingVisible();

    await switchOwner();
    final afterSwitch = env.persistedDreamState();
    held.release();
    await opening;

    expectNothingVisible();
    expect(controller.phase, DreamJourneyPhase.entry);
    expect(controller.history, isEmpty);
    expect(env.ai.calls, 0);
    expect(env.persistedDreamState(), afterSwitch);
  }

  test('A: the supplied Dream is never visible, even transiently', () async {
    final opening = controller.openSaved(stored);
    expectNothingVisible();
    await held.entered;
    expectNothingVisible();
    held.release();
    await opening;
    expect(controller.phase, DreamJourneyPhase.complete);
  });

  test('B: A→B during the lookup fails closed', () async {
    await expectFailsClosed(() => env.switchTo('owner-b'));
  });

  test('C: A→B→A during the lookup fails closed via the epoch', () async {
    await expectFailsClosed(() async {
      await env.switchTo('owner-b');
      await env.switchTo('owner-a');
    });
  });

  test('D: same-owner Dream appears only after verification, as stored',
      () async {
    final opening = controller.openSaved(stored);
    await held.entered;
    expectNothingVisible();
    held.release();
    await opening;

    final shown = controller.dream!;
    expect(controller.phase, DreamJourneyPhase.complete);
    expect(shown.id, stored.id);
    expect(shown.narrative, stored.narrative);
    expect(shown.understanding?.summary, stored.understanding?.summary);
    expect(notified.whereType<Dream>().single.id, stored.id);
    expect(env.ai.calls, 0);
  });

  test('E: a stale same-id caller object shows the stored content', () async {
    final forged = Dream(
      id: stored.id,
      narrative: 'Stale caller prose that storage never held.',
      recordedAt: stored.recordedAt,
    );
    final opening = controller.openSaved(forged);
    await held.entered;
    expectNothingVisible();
    held.release();
    await opening;

    expect(controller.dream!.narrative, phase1NarrativeA);
    expect(controller.dream!.understanding?.summary,
        stored.understanding?.summary);
    expect(env.ai.calls, 0);
  });
}
