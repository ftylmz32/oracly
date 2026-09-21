/// Persist Palm images in app-private storage for saved readings.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/auth/managed_file_path.dart';
import '../../privacy/services/archive_path_kind.dart';

abstract final class PalmImageArchive {
  PalmImageArchive._();

  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}palm_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> persist({
    required String readingId,
    required String sourcePath,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw StateError('palm source missing');
    }
    final safeId = readingId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dest = File(
      '${(await _dir()).path}${Platform.pathSeparator}$safeId.jpg',
    );
    if (src.absolute.path == dest.absolute.path) return dest.path;
    await src.copy(dest.path);
    return dest.path;
  }

  static Future<bool> exists(String? path) async {
    if (path == null || path.trim().isEmpty) return false;
    return File(path).exists();
  }

  static Future<bool> isOwnedPath(String path) async {
    return (await classifyPath(path)) == ArchivePathKind.owned;
  }

  /// Does not create the archive directory (classification is side-effect free).
  static Future<ArchivePathKind> classifyPath(String path) async {
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return ArchivePathKind.notOwned;
      final root = await getApplicationDocumentsDirectory();
      final archive = Directory(
        '${root.path}${Platform.pathSeparator}palm_images',
      );
      final rootNorm = ManagedFilePath.normalize(archive.absolute.path);
      final fileNorm = ManagedFilePath.normalize(File(trimmed).absolute.path);
      return ManagedFilePath.isStrictlyInside(rootNorm, fileNorm)
          ? ArchivePathKind.owned
          : ArchivePathKind.notOwned;
    } catch (_) {
      return ArchivePathKind.unknown;
    }
  }

  static Future<void> deleteIfOwned(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    if (!await isOwnedPath(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<bool> deleteIfOwnedStrict(String? path) async {
    if (path == null || path.trim().isEmpty) return true;
    final kind = await classifyPath(path);
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

  static Future<void> purgeOwnedArchive() async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        try {
          await entity.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// STRICT: path_provider failure is UNKNOWN → false.
  /// Missing archive directory means no orphans → true (do not create it).
  /// Sync FS after documents resolution — avoids dart:io Future stalls.
  static Future<bool> purgeOwnedArchiveStrict() async {
    final Directory dir;
    try {
      final root = await getApplicationDocumentsDirectory();
      dir = Directory('${root.path}${Platform.pathSeparator}palm_images');
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
