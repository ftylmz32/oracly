/// Fincan Haritası photo files in the durable, backup-excluded
/// [CoffeeCupMapLocation]. A photo is kept only once the platform confirms
/// it is excluded from backups; otherwise the copy is removed and nothing is
/// kept. Only files strictly inside that directory are ever deleted here.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/auth/managed_file_path.dart';
import '../../../privacy/services/archive_path_kind.dart';
import 'coffee_cup_map_location.dart';

abstract final class CoffeeCupMapPhotoArchive {
  CoffeeCupMapPhotoArchive._();

  static const photoPrefix = 'photo_';

  static Future<String> persist({
    required String readingId,
    required String sourcePath,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) throw StateError('cup map source missing');
    final location = CoffeeCupMapLocation.instance;
    final dir = await location.directory();
    final safeId = readingId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dest = File(
      '${dir.path}${Platform.pathSeparator}'
      '$photoPrefix${safeId}_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await src.copy(dest.path);
    final excluded = await location.excludeFromBackup(dest.path) &&
        await location.isExcludedFromBackup(dest.path);
    if (!excluded) {
      if (dest.existsSync()) dest.deleteSync();
      throw StateError('cup map photo not excluded from backups');
    }
    return dest.path;
  }

  /// Side-effect free; traversal is notOwned, an unreachable location is
  /// unknown.
  static Future<ArchivePathKind> classify(String path) async {
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return ArchivePathKind.notOwned;
      final dir = await CoffeeCupMapLocation.instance.directory();
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

  /// `true` when the file is gone (or was never ours to delete). A photo
  /// still at its pre-migration cache path is removed from there.
  static Future<bool> deleteStrict(String path) async {
    var kind = await classify(path);
    if (kind == ArchivePathKind.notOwned) {
      kind = await CoffeeCupMapLegacyCache.classify(path);
    }
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

  /// Every file in the directory — photos and the map file — for the
  /// account / history wipes. A platform without the location has kept
  /// nothing there. Sync IO so a wipe cannot stall.
  static Future<bool> purgeStrict() async {
    final Directory dir;
    try {
      dir = await CoffeeCupMapLocation.instance.directory();
      if (!dir.existsSync()) return true;
    } catch (error) {
      return isCoffeeCupMapStorageMissing(error);
    }
    return _deleteFilesIn(dir);
  }
}

/// The cache directory `2e85526d` wrote to (`{cache}/coffee_cup_map`). Read
/// only to migrate from and purged by the wipes; never written again.
abstract final class CoffeeCupMapLegacyCache {
  CoffeeCupMapLegacyCache._();

  static const dirName = 'coffee_cup_map';

  static Future<Directory> _dir() async {
    final root = await getApplicationCacheDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$dirName');
  }

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

  static Future<bool> purgeStrict() async {
    final Directory dir;
    try {
      dir = await _dir();
      if (!dir.existsSync()) return true;
    } catch (_) {
      return false;
    }
    return _deleteFilesIn(dir);
  }
}

bool _deleteFilesIn(Directory dir) {
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
