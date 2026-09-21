/// Deletes app-owned Coffee/Palm archived images before metadata wipe.
library;

import '../../../core/auth/owned_file_cleanup_journal.dart';
import '../../../core/auth/owned_file_cleanup_result.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../coffee/data/coffee_reading_store.dart';
import '../../coffee/services/coffee_image_archive.dart';
import '../../palm/data/palm_reading_store.dart';
import '../../palm/services/palm_image_archive.dart';
import 'archive_path_kind.dart';

abstract final class DiscoveryOwnedImageWipe {
  DiscoveryOwnedImageWipe._();

  /// Best-effort physical cleanup — never blocks metadata wipe.
  static Future<void> wipeCoffeeAndPalmImages(LocalStorage storage) async {
    try {
      await _wipeBody(storage).timeout(const Duration(milliseconds: 800));
    } catch (_) {}
  }

  static Future<void> _wipeBody(LocalStorage storage) async {
    final paths = <String>{};
    for (final reading in CoffeeReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }
    for (final reading in PalmReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }
    for (final path in paths) {
      await CoffeeImageArchive.deleteIfOwned(path);
      await PalmImageArchive.deleteIfOwned(path);
    }
    await CoffeeImageArchive.purgeOwnedArchive();
    await PalmImageArchive.purgeOwnedArchive();
  }

  /// STRICT account-boundary cleanup. See [OwnedFileCleanupResult].
  static Future<OwnedFileCleanupResult> wipeCoffeeAndPalmImagesStrict(
    LocalStorage storage,
  ) async {
    final journalState = OwnedFileCleanupJournal.inspect(storage);
    if (journalState == OwnedFileJournalRead.corrupt) {
      return _reconcileCorruptJournal(storage);
    }

    final paths = <String>{...OwnedFileCleanupJournal.read(storage)};
    for (final reading in CoffeeReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }
    for (final reading in PalmReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }

    final failed = <String>{};
    final resolved = <String>{};
    for (final path in paths) {
      final coffeeOk = await CoffeeImageArchive.deleteIfOwnedStrict(path);
      final palmOk = await PalmImageArchive.deleteIfOwnedStrict(path);
      if (coffeeOk && palmOk) {
        resolved.add(path);
      } else {
        failed.add(path);
      }
    }

    // Always await STRICT archive purge — orphans with empty metadata too.
    final coffeePurgeOk = await CoffeeImageArchive.purgeOwnedArchiveStrict();
    final palmPurgeOk = await PalmImageArchive.purgeOwnedArchiveStrict();

    if (failed.isEmpty && coffeePurgeOk && palmPurgeOk) {
      final journalOk = await OwnedFileCleanupJournal.clear(storage, resolved);
      if (journalOk) return OwnedFileCleanupResult.ok;
      return OwnedFileCleanupResult.retainMetadata;
    }

    if (failed.isNotEmpty) {
      final journalOk = await OwnedFileCleanupJournal.record(storage, failed);
      return journalOk
          ? OwnedFileCleanupResult.incompleteJournaled
          : OwnedFileCleanupResult.retainMetadata;
    }

    // Paths resolved but purge unsettled — fail closed on metadata.
    return OwnedFileCleanupResult.retainMetadata;
  }

  /// Corrupt journal: fail closed, purge owned dirs, reconcile metadata
  /// paths, then retire the corrupt ledger only when every obligation is
  /// proven gone.
  static Future<OwnedFileCleanupResult> _reconcileCorruptJournal(
    LocalStorage storage,
  ) async {
    final coffeePurgeOk = await CoffeeImageArchive.purgeOwnedArchiveStrict();
    final palmPurgeOk = await PalmImageArchive.purgeOwnedArchiveStrict();
    if (!coffeePurgeOk || !palmPurgeOk) {
      return OwnedFileCleanupResult.retainMetadata;
    }

    final paths = <String>{};
    for (final reading in CoffeeReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }
    for (final reading in PalmReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }

    for (final path in paths) {
      final coffeeKind = await CoffeeImageArchive.classifyPath(path);
      final palmKind = await PalmImageArchive.classifyPath(path);
      if (coffeeKind == ArchivePathKind.unknown ||
          palmKind == ArchivePathKind.unknown) {
        return OwnedFileCleanupResult.retainMetadata;
      }
      final coffeeOk = await CoffeeImageArchive.deleteIfOwnedStrict(path);
      final palmOk = await PalmImageArchive.deleteIfOwnedStrict(path);
      if (!coffeeOk || !palmOk) {
        return OwnedFileCleanupResult.retainMetadata;
      }
    }

    // Second purge for any orphan that metadata never referenced.
    if (!await CoffeeImageArchive.purgeOwnedArchiveStrict() ||
        !await PalmImageArchive.purgeOwnedArchiveStrict()) {
      return OwnedFileCleanupResult.retainMetadata;
    }

    if (!await OwnedFileCleanupJournal.retireCorrupt(storage)) {
      return OwnedFileCleanupResult.retainMetadata;
    }
    return OwnedFileCleanupResult.ok;
  }

  static void _addPath(Set<String> paths, String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    paths.add(trimmed);
  }
}
