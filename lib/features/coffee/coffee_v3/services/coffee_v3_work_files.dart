/// App-owned Coffee V3 working photos: the normalized JPEG copies the V3
/// normalizer writes as `{applicationSupport}/coffee_v3_work/coffee_v3_work_{micros}.jpg`.
/// ONLY these are ever deleted by V3 code —
/// never a camera/gallery original, never a V2 (`coffee_v2_work`), Palm or
/// any other file, and never an arbitrary path read from (untrusted)
/// persisted metadata. Ownership = basename prefix AND normalized strict
/// containment in the V3 work directory (traversal is not owned); a
/// path_provider failure is UNKNOWN, never success.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/auth/managed_file_path.dart';
import '../../../privacy/services/archive_path_kind.dart';

abstract final class CoffeeV3WorkFiles {
  CoffeeV3WorkFiles._();

  /// Must match the work-dir name the V3 normalizer passes to
  /// `ImageNormalizer.normalize` (which prefixes files with it).
  static const dirName = 'coffee_v3_work';
  static const filePrefix = '${dirName}_';

  static Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$dirName');
  }

  static bool _ownedName(String path) => path
      .replaceAll('\\', '/')
      .split('/')
      .last
      .startsWith(filePrefix);

  /// Side-effect free (never creates the directory).
  static Future<ArchivePathKind> classify(String? path) async {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty || !_ownedName(trimmed)) return ArchivePathKind.notOwned;
    try {
      final dirNorm = ManagedFilePath.normalize((await _dir()).absolute.path);
      final fileNorm = ManagedFilePath.normalize(File(trimmed).absolute.path);
      return ManagedFilePath.isStrictlyInside(dirNorm, fileNorm)
          ? ArchivePathKind.owned
          : ArchivePathKind.notOwned;
    } catch (_) {
      return ArchivePathKind.unknown;
    }
  }

  static Future<bool> isOwned(String? path) async =>
      await classify(path) == ArchivePathKind.owned;

  /// STRICT single delete. `true` = nothing owned remains at [path] (also
  /// for a not-owned path, which is never touched, and for a missing file).
  /// `false` = ownership unknown or the delete failed — retry needed.
  static Future<bool> deleteIfOwnedStrict(String? path) async {
    final kind = await classify(path);
    if (kind == ArchivePathKind.notOwned) return true;
    if (kind == ArchivePathKind.unknown) return false;
    try {
      final file = File(path!.trim());
      if (file.existsSync()) file.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// STRICT account-boundary purge of every V3 working photo. A missing
  /// directory means nothing to clean (`true`, directory not created).
  /// Only plain files carrying the V3 prefix are deleted; sub-directories
  /// and links are never followed or removed. path_provider failure or any
  /// failed delete returns `false` — the caller must not report a complete
  /// privacy wipe, and the files stay findable for the next run. Sync FS
  /// after directory resolution (mirrors the archive purge).
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
        if (entity is! File || !_ownedName(entity.path)) continue;
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
