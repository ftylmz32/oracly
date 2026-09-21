/// Durable record of app-owned files a STRICT account-boundary wipe could
/// not physically delete — keeps their paths findable for a retry even
/// after the metadata that originally pointed to them (a reading's
/// imagePath, say) has already been cleared by a later, independent step
/// of the same wipe run. Without this, a failed delete plus an unconditional
/// later metadata clear would orphan the file forever: nothing would ever
/// know it still exists.
library;

import '../data/datasources/local_storage.dart';

enum OwnedFileJournalRead { absent, valid, corrupt }

abstract final class OwnedFileCleanupJournal {
  OwnedFileCleanupJournal._();

  static const key = 'account_owned_file_cleanup_pending';

  /// Type-safe journal inspect — a wrong-type value is UNKNOWN, never
  /// silently "no pending files".
  static OwnedFileJournalRead inspect(LocalStorage storage) {
    final raw = storage.peek(key);
    if (raw == null) return OwnedFileJournalRead.absent;
    if (raw is List<String>) return OwnedFileJournalRead.valid;
    if (raw is List && raw.every((e) => e is String)) {
      return OwnedFileJournalRead.valid;
    }
    return OwnedFileJournalRead.corrupt;
  }

  static Set<String> read(LocalStorage storage) {
    if (inspect(storage) != OwnedFileJournalRead.valid) return <String>{};
    final raw = storage.getStringList(key);
    if (raw == null) return <String>{};
    return raw.toSet();
  }

  /// Merges [paths] into the durably-recorded pending set. Returns whether
  /// the merged write itself succeeded — a caller must treat `false` here
  /// as its own failure, since a path that fails to even get JOURNALED
  /// could otherwise be lost the moment its owning metadata is cleared.
  static Future<bool> record(LocalStorage storage, Set<String> paths) async {
    if (paths.isEmpty) return true;
    if (inspect(storage) == OwnedFileJournalRead.corrupt) return false;
    final merged = read(storage)..addAll(paths);
    return storage.setStringList(key, merged.toList());
  }

  /// Drops [resolvedPaths] (successfully deleted) from the pending set.
  static Future<bool> clear(
    LocalStorage storage,
    Set<String> resolvedPaths,
  ) async {
    if (inspect(storage) == OwnedFileJournalRead.corrupt) return false;
    final remaining = read(storage)..removeAll(resolvedPaths);
    if (remaining.isEmpty) return storage.remove(key);
    return storage.setStringList(key, remaining.toList());
  }
}
