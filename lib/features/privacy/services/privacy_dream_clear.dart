/// Discovery clear, Dream scope — records, memory, version chains, attempt.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/repositories/local_dream_repository.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_store.dart';
import '../../dream/services/dream_attempt_store.dart';
import '../../dream/services/dream_owner_guard.dart';

abstract final class PrivacyDreamClear {
  PrivacyDreamClear._();

  /// Attempts every step. Returns true only when the version chains and the
  /// attempt row (which can still hold narrative text) were durably removed.
  static Future<bool> run(LocalStorage storage, OraclyMemoryStore memory) async {
    // First, so an analysis already in flight cannot re-persist afterwards.
    DreamOwnerGuard.markCleared();

    final repo = LocalDreamRepository(storage, memory: memory);
    final ids = <String>{};
    try {
      ids.addAll((await repo.getAll()).map((e) => e.id));
    } catch (_) {}
    for (final id in ids) {
      try {
        await repo.delete(id);
      } catch (_) {}
    }

    var durable = true;
    try {
      await ReadingVersionStore(storage).removeKind(
        ReadingVersionKind.dream,
        rootIds: ids,
      );
    } catch (_) {
      durable = false;
    }
    try {
      await DreamAttemptStore(storage).clear();
    } catch (_) {
      durable = false;
    }
    return durable;
  }
}
