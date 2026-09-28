/// Dream final audit §20 — a success is shown only when the record and its
/// version root are both durable; a partial write leaves nothing behind.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';

import 'dream_phase1_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<DreamPhase1Env> faultable() => DreamPhase1Env.open(faultable: true);

  test('success persists record, connected memory and version root', () async {
    final env = await DreamPhase1Env.open();
    final result = await env.service().analyze(narrative: phase1NarrativeA);
    expect(env.recordCount, 1);
    expect(env.dreamMemoryCount, 1);
    expect(env.versionsRaw, contains(result.dream.id));
    expect((await env.repo.getById(result.dream.id))?.text, phase1NarrativeA);
  });

  test('a record write that resolves false is a failure, not a success', () async {
    final env = await faultable();
    env.faults.falseReturnKeys.add('dream_records');
    await expectLater(env.service().analyze(narrative: phase1NarrativeA), throwsA(anything));
    expect(env.recordCount, 0);
    expect(env.versionsRaw ?? '', isNot(contains('"kind":"dream"')));
  });

  test('a record write that throws persists nothing else', () async {
    final env = await faultable();
    env.faults.throwingKeys.add('dream_records');
    await expectLater(env.service().analyze(narrative: phase1NarrativeA), throwsA(anything));
    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(env.versionsRaw ?? '', isNot(contains('"kind":"dream"')));
  });

  for (final mode in ['false', 'throw']) {
    test('a version root write ($mode) after the record reverts the record', () async {
      final env = await faultable();
      (mode == 'false' ? env.faults.falseReturnKeys : env.faults.throwingKeys)
          .add(ReadingVersionStore.key);
      await expectLater(env.service().analyze(narrative: phase1NarrativeA), throwsA(anything));
      expect(env.recordCount, 0, reason: 'no orphan record behind an error');
      expect(env.dreamMemoryCount, 0, reason: 'no orphan connected memory');
    });
  }

  test('retry after a partial failure leaves exactly one record', () async {
    final env = await faultable();
    env.faults.throwingKeys.add(ReadingVersionStore.key);
    await expectLater(env.service().analyze(narrative: phase1NarrativeA), throwsA(anything));
    env.faults.throwingKeys.clear();
    await env.service().analyze(narrative: phase1NarrativeA);
    expect(env.recordCount, 1);
    expect(env.dreamMemoryCount, 1);
  });

  test('the controller shows an error, never a result, on a partial write', () async {
    final env = await faultable();
    env.faults.falseReturnKeys.add('dream_records');
    final controller = DreamAnalysisController(env.service(), organizingDelay: Duration.zero);
    await controller.submit(narrative: phase1NarrativeA);
    expect(controller.phase, DreamJourneyPhase.error);
    expect(controller.dream, isNull);
    expect(controller.history, isEmpty);
    controller.dispose();
  });

  test('an earlier Dream and its memory survive a reverted Dream write', () async {
    final env = await faultable();
    await env.service().analyze(narrative: phase1NarrativeA2);
    final before = env.storage.getStringList(OraclyMemoryStore.key)?.length ?? 0;
    expect(before, greaterThan(0));
    env.faults.throwingKeys.add(ReadingVersionStore.key);
    await expectLater(env.service().analyze(narrative: phase1NarrativeA), throwsA(anything));
    expect(env.storage.getStringList(OraclyMemoryStore.key)?.length ?? 0, before);
    expect(env.recordCount, 1);
  });
}
