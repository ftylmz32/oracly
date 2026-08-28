/// Seeds and appends reinterpret versions — never duplicates journal rows.
library;

import '../models/reading_version_append_result.dart';
import '../models/reading_version_entry.dart';
import '../models/reading_version_group.dart';
import '../models/reading_version_kind.dart';
import 'reading_version_fingerprint.dart';
import 'reading_version_store.dart';

class ReadingVersionService {
  ReadingVersionService(this._store);

  final ReadingVersionStore _store;

  ReadingVersionGroup? groupFor(String rootId) => _store.byRootId(rootId);

  Future<ReadingVersionGroup> seedOriginal({
    required String rootId,
    required ReadingVersionKind kind,
    required Map<String, dynamic> data,
  }) async {
    final existing = _store.byRootId(rootId);
    if (existing != null && existing.entries.isNotEmpty) return existing;
    final entry = _entry(number: 1, kind: kind, data: data);
    final group = ReadingVersionGroup(
      rootId: rootId,
      kind: kind,
      entries: [entry],
      activeNumber: 1,
    );
    await _store.save(group);
    return group;
  }

  Future<ReadingVersionAppendResult> tryAppendRevision({
    required String rootId,
    required ReadingVersionKind kind,
    required Map<String, dynamic> data,
  }) async {
    var group = _store.byRootId(rootId);
    group ??= await seedOriginal(rootId: rootId, kind: kind, data: data);
    final fingerprint = ReadingVersionFingerprint.of(data, kind);
    final active = group.activeEntry;
    if (active != null && active.fingerprint == fingerprint) {
      return ReadingVersionAppendResult(added: false, group: group);
    }
    final nextNumber = group.entries.length + 1;
    final entry = ReadingVersionEntry(
      number: nextNumber,
      at: DateTime.now(),
      fingerprint: fingerprint,
      data: data,
    );
    group = group.copyWith(
      entries: [...group.entries, entry],
      activeNumber: nextNumber,
    );
    await _store.save(group);
    return ReadingVersionAppendResult(added: true, group: group);
  }

  Future<ReadingVersionGroup> selectVersion({
    required String rootId,
    required int number,
  }) async {
    final group = _store.byRootId(rootId);
    if (group == null || group.entryFor(number) == null) {
      throw StateError('reading version missing');
    }
    final next = group.copyWith(activeNumber: number);
    await _store.save(next);
    return next;
  }

  ReadingVersionEntry _entry({
    required int number,
    required ReadingVersionKind kind,
    required Map<String, dynamic> data,
  }) {
    return ReadingVersionEntry(
      number: number,
      at: DateTime.now(),
      fingerprint: ReadingVersionFingerprint.of(data, kind),
      data: data,
    );
  }
}
