/// Deletes app-owned Coffee/Palm archived images before metadata wipe.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../coffee/data/coffee_reading_store.dart';
import '../../coffee/services/coffee_image_archive.dart';
import '../../palm/data/palm_reading_store.dart';
import '../../palm/services/palm_image_archive.dart';

abstract final class DiscoveryOwnedImageWipe {
  DiscoveryOwnedImageWipe._();

  /// Best-effort physical cleanup ? never blocks metadata wipe.
  static Future<void> wipeCoffeeAndPalmImages(LocalStorage storage) async {
    try {
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
    } catch (_) {}
  }

  static void _addPath(Set<String> paths, String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    paths.add(trimmed);
  }
}
