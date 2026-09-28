/// Dream Final Audit.1 — a new Dream is committed record-last: no visible
/// Dream record may exist before its version root is durable, whatever
/// rollback can or cannot do. Controlled fakes; no storage call ordering.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_group.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/services/dream_experience_commit.dart';
import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

class _Repo implements DreamRepository {
  _Repo(this.log);

  final List<String> log;
  final rows = <String, DreamRecord>{};
  int saves = 0;
  bool saveThrows = false;
  bool deleteThrows = true;

  @override
  Future<void> save(DreamRecord record) async {
    saves++;
    log.add('save');
    if (saveThrows) throw StateError('record write failed');
    rows[record.id] = record;
  }

  @override
  Future<void> delete(String id) async {
    log.add('delete');
    if (deleteThrows) throw StateError('record delete failed');
    rows.remove(id);
  }

  @override
  Future<List<DreamRecord>> getAll() async => rows.values.toList();
  @override
  Future<DreamRecord?> getById(String id) async => rows[id];
  @override
  Future<void> sync() async {}
}

class _Versions extends ReadingVersionService {
  _Versions(this.store, this.log) : super(store);

  final ReadingVersionStore store;
  final List<String> log;
  bool seedThrows = false;
  bool removeThrows = false;
  Completer<void>? pauseAfterSeed;
  int removes = 0;

  @override
  Future<ReadingVersionGroup> seedOriginal({
    required String rootId,
    required ReadingVersionKind kind,
    required Map<String, dynamic> data,
  }) async {
    log.add('seed');
    if (seedThrows) throw StateError('version root write failed');
    final group = await super.seedOriginal(rootId: rootId, kind: kind, data: data);
    final pause = pauseAfterSeed;
    if (pause != null) await pause.future;
    return group;
  }

  @override
  Future<void> removeRoot(String rootId) async {
    removes++;
    log.add('removeRoot');
    if (removeThrows) throw StateError('root cleanup failed');
    await super.removeRoot(rootId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> log;
  late _Repo repo;
  late _Versions versions;
  late String ownerId;
  late DreamOwnerGuard guard;
  late DreamExperienceCommit commit;
  final dream = Dream(
    id: 'dream_audit1',
    narrative: 'Rüyamda eski evimin açık penceresinden sessiz bir deniz görünüyordu.',
    recordedAt: DateTime(2026, 9, 28),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = FalseReturnLocalStorage(await SharedPreferences.getInstance());
    log = [];
    repo = _Repo(log);
    versions = _Versions(ReadingVersionStore(storage), log);
    ownerId = 'owner-a';
    guard = DreamOwnerGuard(ownerId: () => ownerId);
    commit = DreamExperienceCommit(repository: repo, owner: guard, versions: versions);
  });

  Future<DreamExperienceResult> run() =>
      commit.commit(dream: dream, snapshot: guard.capture(), isRevision: false);

  test('version root fails and rollback delete fails: no visible record', () async {
    versions.seedThrows = true;
    await expectLater(run(), throwsStateError);
    // VISIBLE DREAM RECORD WRITTEN BEFORE FAILED VERSION ROOT: NO
    expect(repo.saves, 0);
    expect(repo.rows, isEmpty);
    expect(log.first, 'seed');
  });

  test('success order: root → record; nothing cleaned up', () async {
    final result = await run();
    expect(result.dream.id, dream.id);
    expect(log, ['seed', 'save']);
    expect(repo.rows.keys, [dream.id]);
    expect(versions.store.byRootId(dream.id), isNotNull);
  });

  test('record save fails after the root: error, 0 records, root removed', () async {
    repo.saveThrows = true;
    await expectLater(run(), throwsStateError);
    expect(repo.rows, isEmpty);
    expect(versions.removes, 1);
    expect(versions.store.byRootId(dream.id), isNull);
  });

  test('record save and root cleanup both fail: only a hidden root remains',
      () async {
    repo.saveThrows = true;
    versions.removeThrows = true;
    await expectLater(run(), throwsStateError);
    expect(repo.rows, isEmpty, reason: 'never a user-visible Dream record');
    expect(versions.removes, 1);
    expect(versions.store.byRootId(dream.id), isNotNull,
        reason: 'documented hidden version-root orphan');
  });

  test('owner switch between root and record: record never written', () async {
    final pause = versions.pauseAfterSeed = Completer<void>();
    final pending = run();
    await Future<void>.delayed(Duration.zero);
    expect(log, ['seed']);
    ownerId = 'owner-b';
    pause.complete();

    await expectLater(pending, throwsA(isA<DreamOwnerChangedException>()));
    expect(repo.saves, 0);
    expect(repo.rows, isEmpty, reason: 'visible to neither owner');
    expect(versions.removes, 1);
    expect(versions.store.byRootId(dream.id), isNull);
  });

  test('owner switch before any write: nothing is written', () async {
    final snapshot = guard.capture();
    ownerId = 'owner-b';
    await expectLater(
      commit.commit(dream: dream, snapshot: snapshot, isRevision: false),
      throwsA(isA<DreamOwnerChangedException>()),
    );
    expect(log, isEmpty);
  });
}
