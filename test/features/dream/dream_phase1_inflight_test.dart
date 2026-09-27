/// Dream Phase 1 — Tests C/D + post-save race: in-flight A never lands in B.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';

import 'dream_phase1_support.dart';

/// Completes an owner switch between the durable save and the post-check.
class _SwitchDuringSaveRepository implements DreamRepository {
  _SwitchDuringSaveRepository(this._inner);

  final DreamRepository _inner;

  @override
  Future<void> save(DreamRecord record) async {
    await _inner.save(record);
    UserLocalDataIsolation.accountSwitchEpoch.value++;
  }

  @override
  Future<List<DreamRecord>> getAll() => _inner.getAll();

  @override
  Future<DreamRecord?> getById(String id) => _inner.getById(id);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<void> sync() => _inner.sync();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DreamPhase1Env env;

  setUp(() async {
    env = await DreamPhase1Env.open(ai: HeldDreamAi(hold: true));
  });

  test('C: in-flight A analysis released after A→B is not persisted', () async {
    final pending = env.service().analyze(narrative: phase1NarrativeA);
    await env.ai.entered;

    await env.switchTo('owner-b');
    env.ai.hold = false;
    await env.service().analyze(narrative: phase1NarrativeA2);
    expect(env.recordCount, 1);
    final before = env.persistedDreamState();

    env.ai.release();
    await expectLater(pending, throwsA(isA<DreamOwnerChangedException>()));

    expect(env.recordCount, 1);
    expect(env.persistedDreamState(), before);
    expect(
      (await env.repo.getAll()).single.text,
      phase1NarrativeA2,
    );
  });

  test('C: controller shows nothing from the released A operation', () async {
    final controller = DreamAnalysisController(
      env.service(),
      organizingDelay: Duration.zero,
    );
    final submit = controller.submit(narrative: phase1NarrativeA);
    await env.ai.entered;

    await env.switchTo('owner-b');
    final before = env.persistedDreamState();
    env.ai.release();
    await submit;

    expect(controller.phase, DreamJourneyPhase.entry);
    expect(controller.dream, isNull);
    expect(controller.history, isEmpty);
    expect(env.persistedDreamState(), before);
    controller.dispose();
  });

  test('D: A→B→A before release is still rejected by the epoch', () async {
    final pending = env.service().analyze(narrative: phase1NarrativeA);
    await env.ai.entered;

    await env.switchTo('owner-b');
    await env.switchTo('owner-a');
    expect(
      env.storage.getString(UserLocalDataIsolation.ownerKey),
      'owner-a',
    );
    final before = env.persistedDreamState();

    env.ai.release();
    await expectLater(pending, throwsA(isA<DreamOwnerChangedException>()));

    expect(env.recordCount, 0);
    expect(env.dreamMemoryCount, 0);
    expect(env.persistedDreamState(), before);
  });

  test('owner key missing fails closed before the provider is called',
      () async {
    await env.storage.remove(UserLocalDataIsolation.ownerKey);
    env.ai.hold = false;

    await expectLater(
      env.service().analyze(narrative: phase1NarrativeA),
      throwsA(isA<AiRequestException>()),
    );
    expect(env.ai.calls, 0);
    expect(env.recordCount, 0);
  });

  test('post-save race: switch landing mid-save reverts only this dream',
      () async {
    env.ai.hold = false;
    await env.service().analyze(narrative: phase1NarrativeA2);
    final kept = (await env.repo.getAll()).single.id;
    // Dream ids are millisecond-minted; keep the two operations distinct.
    await Future<void>.delayed(const Duration(milliseconds: 3));

    final racing = DreamExperienceService(
      repository: _SwitchDuringSaveRepository(env.repo),
      ai: env.ai,
      owner: DreamOwnerGuard.fromStorage(env.storage),
      versions: env.versions,
    );
    await expectLater(
      racing.analyze(narrative: phase1NarrativeA),
      throwsA(isA<DreamOwnerChangedException>()),
    );

    final remaining = await env.repo.getAll();
    expect(remaining.map((r) => r.id), [kept]);
    expect(env.dreamMemoryCount, 1);
    expect(env.versions.groupFor(kept), isNotNull);
    expect(env.versionsRaw, isNot(contains(phase1NarrativeA)));
  });
}
