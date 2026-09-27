// Dream Phase 4A — Test F: history is read for exactly one owner snapshot;
// a switch during the read fails closed before the provider is called.
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';

import 'dream_phase1_support.dart';
import 'dream_phase4a_support.dart';

class _CapturingAi extends HeldDreamAi {
  final contexts = <DreamAiContext>[];

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    contexts.add(context);
    return super.analyzeDream(context);
  }
}

/// Runs [onFirstRead] after the first full read returns, before the caller
/// sees the records — the window a post-read owner check must cover.
class _SwitchAfterReadRepository implements DreamRepository {
  _SwitchAfterReadRepository(this._inner, this.onFirstRead);

  final DreamRepository _inner;
  final Future<void> Function() onFirstRead;
  bool _done = false;

  @override
  Future<List<DreamRecord>> getAll() async {
    final records = await _inner.getAll();
    if (!_done) {
      _done = true;
      await onFirstRead();
    }
    return records;
  }

  @override
  Future<void> save(DreamRecord record) => _inner.save(record);

  @override
  Future<DreamRecord?> getById(String id) => _inner.getById(id);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<void> sync() => _inner.sync();
}

DateTime _past(int d) => DateTime(2021, 3, d, 9);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DreamPhase1Env env;
  late _CapturingAi ai;

  setUp(() async {
    ai = _CapturingAi();
    env = await DreamPhase1Env.open(ai: ai);
    await seed(env.repo, [
      savedDream('p1', doorTr, _past(1)),
      savedDream('p2', doorTr2, _past(2)),
    ]);
  });

  DreamExperienceService racing(Future<void> Function() onRead) =>
      DreamExperienceService(
        repository: _SwitchAfterReadRepository(env.repo, onRead),
        ai: ai,
        owner: DreamOwnerGuard.fromStorage(env.storage),
        versions: env.versions,
      );

  test('A recurring history never reaches B', () async {
    await env.service().analyze(narrative: doorTr3);
    expect(ai.contexts.single.history.single['level'], 'recurring');

    await env.switchTo('owner-b');
    await env.service().analyze(narrative: doorTr3);
    expect(ai.contexts.last.history, isEmpty);
  });

  test('A→B during the history read fails closed; provider never called',
      () async {
    await expectLater(
      racing(() => env.switchTo('owner-b')).analyze(narrative: doorTr3),
      throwsA(isA<DreamOwnerChangedException>()),
    );
    expect(ai.calls, 0);
    expect(env.recordCount, 0);
  });

  test('A→B→A during the history read is rejected by the epoch', () async {
    await expectLater(
      racing(() async {
        await env.switchTo('owner-b');
        await env.switchTo('owner-a');
      }).analyze(narrative: doorTr3),
      throwsA(isA<DreamOwnerChangedException>()),
    );
    expect(
      env.storage.getString(UserLocalDataIsolation.ownerKey),
      'owner-a',
    );
    expect(ai.calls, 0);
    expect(env.recordCount, 0);
  });
}
