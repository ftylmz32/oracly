/// One app-owned Coffee normalizer working directory —
/// `{applicationSupport}/{dirName}/{dirName}_*` — the exact location and
/// filename prefix `ImageNormalizer.normalize(source, dirName, ...)` writes
/// its normalized JPEG copies to. The single strict ownership primitive for
/// every Coffee work dir (V2 `coffee_v2_work`, V3 `coffee_v3_work`):
///
/// * owned = basename prefix AND normalized strict containment in the dir
///   (traversal such as `dir/../x` is NOT owned);
/// * a path_provider failure is UNKNOWN — never permission to delete and
///   never reported as a successful cleanup;
/// * only plain files are deleted — links and sub-directories are never
///   followed or removed; camera/gallery originals, other features' files
///   and arbitrary paths read from persisted metadata are never touched.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/auth/managed_file_path.dart';
import '../../privacy/services/archive_path_kind.dart';

class CoffeeOwnedWorkDir {
  const CoffeeOwnedWorkDir(this.dirName);

  /// Must equal the `workDirName` the matching normalizer passes to
  /// `ImageNormalizer.normalize` (which also prefixes every file with it).
  final String dirName;

  String get filePrefix => '${dirName}_';

  Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$dirName');
  }

  bool _ownedName(String path) =>
      path.replaceAll('\\', '/').split('/').last.startsWith(filePrefix);

  /// Side-effect free (never creates the directory).
  Future<ArchivePathKind> classify(String? path) async {
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

  Future<bool> isOwned(String? path) async =>
      await classify(path) == ArchivePathKind.owned;

  /// STRICT single delete. `true` = nothing owned remains at [path] (also
  /// for a not-owned path, which is never touched, and a missing file).
  /// `false` = ownership unknown or the delete failed — retry needed.
  Future<bool> deleteIfOwnedStrict(String? path) async {
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

  /// STRICT account-boundary purge of every owned working file. A missing
  /// directory means nothing to clean (`true`; the directory is not
  /// created). path_provider failure or any failed delete returns `false`
  /// — the caller must not report a complete privacy wipe. Sync FS after
  /// directory resolution (mirrors the archive purge).
  Future<bool> purgeStrict() async {
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
