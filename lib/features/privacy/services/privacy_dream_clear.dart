/// Discovery clear, Dream scope — records, memory, version chains, attempt.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/datasources/storage_result.dart';
import '../../../core/data/repositories/local_dream_repository.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_store.dart';
import '../../dream/services/dream_attempt_store.dart';
import '../../dream/services/dream_owner_guard.dart';

abstract final class PrivacyDreamClear {
  PrivacyDreamClear._();

  static const recordsKey = 'dream_records';

  /// Attempts every step. Returns true only when Dream records (malformed
  /// rows included), Dream memory, Dream version chains and the attempt row
  /// were all durably removed — a false write or a throw is incomplete.
  static Future<bool> run(LocalStorage storage, OraclyMemoryStore memory) async {
    // First, so an analysis already in flight cannot re-persist afterwards.
    DreamOwnerGuard.markCleared();

    final ids = <String>{};
    try {
      final repo = LocalDreamRepository(storage);
      ids.addAll((await repo.getAll()).map((e) => e.id));
    } catch (_) {}

    var durable = true;
    for (final step in <Future<void> Function()>[
      // Records first: a later partial failure can never resurface them.
      () => storage.setStringList(recordsKey, const []).requireDurable(),
      () => _purgeMemory(storage, memory),
      () => ReadingVersionStore(storage).removeKind(
            ReadingVersionKind.dream,
            rootIds: ids,
          ),
      () => DreamAttemptStore(storage).clear(),
    ]) {
      try {
        await step();
      } catch (_) {
        durable = false;
      }
    }
    return durable;
  }

  /// Removes Dream connected-memory rows; every other readable type is kept.
  /// Unparseable rows cannot be proven non-Dream, so they go too.
  static Future<void> _purgeMemory(
    LocalStorage storage,
    OraclyMemoryStore memory,
  ) async {
    final rawCount = storage.getStringList(OraclyMemoryStore.key)?.length ?? 0;
    final kept = memory
        .all()
        .where((m) => m.source.type != OraclyReadingType.dream)
        .toList();
    if (kept.length == rawCount) return;
    await storage
        .setStringList(
          OraclyMemoryStore.key,
          kept.map((e) => jsonEncode(e.toJson())).toList(),
        )
        .requireDurable();
  }
}
