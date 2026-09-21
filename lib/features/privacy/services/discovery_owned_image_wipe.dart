/// Deletes app-owned Coffee/Palm archived images before metadata wipe.
library;

import '../../../core/auth/owned_file_cleanup_journal.dart';
import '../../../core/auth/owned_file_cleanup_result.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../coffee/data/coffee_reading_store.dart';
import '../../coffee/services/coffee_image_archive.dart';
import '../../palm/data/palm_reading_store.dart';
import '../../palm/services/palm_image_archive.dart';

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

  /// STRICT account-boundary cleanup. See [OwnedFileCleanupResult] for when
  /// Coffee/Palm metadata may still be cleared after an incomplete pass.
  static Future<OwnedFileCleanupResult> wipeCoffeeAndPalmImagesStrict(
    LocalStorage storage,
  ) async {
    final journalState = OwnedFileCleanupJournal.inspect(storage);
    if (journalState == OwnedFileJournalRead.corrupt) {
      // UNKNOWN ledger — fail closed; never treat as "no pending files"
      // and never authorize metadata erase that would orphan survivors.
      await CoffeeImageArchive.purgeOwnedArchiveStrict();
      await PalmImageArchive.purgeOwnedArchiveStrict();
      return OwnedFileCleanupResult.retainMetadata;
    }

    final paths = <String>{...OwnedFileCleanupJournal.read(storage)};
    for (final reading in CoffeeReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }
    for (final reading in PalmReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }

    if (paths.isEmpty) {
      // ignore: unawaited_futures
      CoffeeImageArchive.purgeOwnedArchive();
      // ignore: unawaited_futures
      PalmImageArchive.purgeOwnedArchive();
      return OwnedFileCleanupResult.ok;
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

    if (failed.isEmpty) {
      final journalOk = await OwnedFileCleanupJournal.clear(storage, resolved);
      final coffeePurgeOk = await CoffeeImageArchive.purgeOwnedArchiveStrict();
      final palmPurgeOk = await PalmImageArchive.purgeOwnedArchiveStrict();
      if (journalOk && coffeePurgeOk && palmPurgeOk) {
        return OwnedFileCleanupResult.ok;
      }
      // Resolved deletes but journal/purge unsettled — metadata still has
      // nothing left to point at resolved paths; journal clear failure of
      // an empty/near-empty set is rare. Fail closed without blocking
      // metadata if all physical paths resolved.
      return journalOk
          ? OwnedFileCleanupResult.incompleteJournaled
          : OwnedFileCleanupResult.retainMetadata;
    }

    final journalOk = await OwnedFileCleanupJournal.record(storage, failed);
    await CoffeeImageArchive.purgeOwnedArchiveStrict();
    await PalmImageArchive.purgeOwnedArchiveStrict();
    return journalOk
        ? OwnedFileCleanupResult.incompleteJournaled
        : OwnedFileCleanupResult.retainMetadata;
  }

  static void _addPath(Set<String> paths, String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    paths.add(trimmed);
  }
}
