/// Where Fincan Haritası keeps a reading's photos: `coffee_cup_map/` in
/// the app's CACHE directory (Android `getCacheDir()`, iOS
/// `Library/Caches`). Both platforms document that location as left out of
/// device backups; the trade-off is that the OS may clear it to free space,
/// which the map shows as "photo no longer on this device". Only files
/// strictly inside that directory are ever deleted here.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/auth/managed_file_path.dart';
import '../../../privacy/services/archive_path_kind.dart';

abstract final class CoffeeCupMapPhotoArchive {
  CoffeeCupMapPhotoArchive._();

  static const dirName = 'coffee_cup_map';

  static Future<Directory> _dir() async {
    final root = await getApplicationCacheDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$dirName');
  }

  static Future<String> persist({
    required String readingId,
    required String sourcePath,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) throw StateError('cup map source missing');
    final dir = await _dir();
    if (!await dir.exists()) await dir.create(recursive: true);
    final safeId = readingId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dest = File(
      '${dir.path}${Platform.pathSeparator}'
      '${safeId}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await src.copy(dest.path);
    return dest.path;
  }

  /// Side-effect free; traversal is notOwned, a path_provider failure is
  /// unknown.
  static Future<ArchivePathKind> classify(String path) async {
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return ArchivePathKind.notOwned;
      final dir = await _dir();
      return ManagedFilePath.isStrictlyInside(
        ManagedFilePath.normalize(dir.absolute.path),
        ManagedFilePath.normalize(File(trimmed).absolute.path),
      )
          ? ArchivePathKind.owned
          : ArchivePathKind.notOwned;
    } catch (_) {
      return ArchivePathKind.unknown;
    }
  }

  /// `true` when the file is gone (or was never ours to delete).
  static Future<bool> deleteStrict(String path) async {
    final kind = await classify(path);
    if (kind == ArchivePathKind.notOwned) return true;
    if (kind == ArchivePathKind.unknown) return false;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Every file in the directory, for the account / history wipes. A
  /// missing directory is already clean; sync IO so a wipe cannot stall.
  static Future<bool> purgeStrict() async {
    final Directory dir;
    try {
      dir = await _dir();
      if (!dir.existsSync()) return true;
    } catch (_) {
      return false;
    }
    var ok = true;
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! File) continue;
        try {
          entity.deleteSync();
        } catch (_) {
          ok = false;
        }
      }
    } catch (_) {
      return false;
    }
    return ok;
  }
}
