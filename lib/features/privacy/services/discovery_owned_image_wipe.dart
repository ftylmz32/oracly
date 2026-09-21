/// Deletes app-owned Coffee/Palm archived images before metadata wipe.
library;

import '../../../core/auth/owned_file_cleanup_journal.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../coffee/data/coffee_reading_store.dart';
import '../../coffee/services/coffee_image_archive.dart';
import '../../palm/data/palm_reading_store.dart';
import '../../palm/services/palm_image_archive.dart';

abstract final class DiscoveryOwnedImageWipe {
  DiscoveryOwnedImageWipe._();

  /// Best-effort physical cleanup — never blocks metadata wipe. Retained
  /// only for callers outside the account-boundary wipe; the wipe itself
  /// uses [wipeCoffeeAndPalmImagesStrict], which is awaited and honest.
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

  /// STRICT account-boundary cleanup — MUST be awaited by
  /// [UserLocalDataWipe] before the Coffee/Palm reading metadata (which is
  /// where these paths come from) is itself cleared. Returns `false` if
  /// ANY owned file could not be proven deleted; the caller must then
  /// treat the whole wipe as incomplete rather than "complete".
  ///
  /// Owned paths are captured from CURRENT reading metadata PLUS whatever
  /// [OwnedFileCleanupJournal] already has pending from an earlier failed
  /// attempt — the metadata for a path that failed last time may already
  /// be gone (a LATER step in the same earlier wipe run still cleared it
  /// unconditionally), so the journal is the only place that path can
  /// still be found. Paths that fail here are (re-)recorded to the
  /// journal BEFORE this returns, so they survive even if this run's
  /// metadata-clearing steps proceed anyway.
  static Future<bool> wipeCoffeeAndPalmImagesStrict(
    LocalStorage storage,
  ) async {
    final paths = <String>{...OwnedFileCleanupJournal.read(storage)};
    for (final reading in CoffeeReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }
    for (final reading in PalmReadingStore(storage).all()) {
      _addPath(paths, reading.imagePath);
    }

    // Nothing known to delete (and nothing journaled from a prior failure):
    // there is no owned-file obligation left to prove. A background orphan
    // sweep of the archive dirs remains best-effort — it must never block
    // account-boundary completion on path_provider availability.
    if (paths.isEmpty) {
      // ignore: unawaited_futures
      CoffeeImageArchive.purgeOwnedArchive();
      // ignore: unawaited_futures
      PalmImageArchive.purgeOwnedArchive();
      return true;
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

    final journalOk = failed.isEmpty
        ? await OwnedFileCleanupJournal.clear(storage, resolved)
        : await OwnedFileCleanupJournal.record(storage, failed);

    final coffeePurgeOk = await CoffeeImageArchive.purgeOwnedArchiveStrict();
    final palmPurgeOk = await PalmImageArchive.purgeOwnedArchiveStrict();

    return failed.isEmpty && journalOk && coffeePurgeOk && palmPurgeOk;
  }

  static void _addPath(Set<String> paths, String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    paths.add(trimmed);
  }
}
