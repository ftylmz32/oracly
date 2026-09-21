/// Persist Palm images in app-private storage for saved readings.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract final class PalmImageArchive {
  PalmImageArchive._();

  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}palm_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copy normalized source into durable app-owned path for [readingId].
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
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return false;
      final root = _ownedPrefix(await _dir());
      return File(trimmed).absolute.path.startsWith(root);
    } catch (_) {
      return false;
    }
  }

  /// Delete archived image when reading is removed — never touch external paths.
  static Future<void> deleteIfOwned(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    if (!await isOwnedPath(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Account-boundary wipe variant — used only by [DiscoveryOwnedImageWipe].
  /// Never touches a path outside this archive (returns `true` — nothing
  /// owned to clean up). Returns `false` only when an OWNED file's delete
  /// itself failed, so the caller can keep the path for retry instead of
  /// silently treating the file as gone.
  static Future<bool> deleteIfOwnedStrict(String? path) async {
    if (path == null || path.trim().isEmpty) return true;
    if (!await isOwnedPath(path)) return true;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove every file under the palm archive directory.
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

  /// Account-boundary wipe variant — returns `false` if a file THAT WAS
  /// FOUND under the archive directory could not be deleted. If the
  /// directory/platform itself is unreachable (e.g. path_provider isn't
  /// wired up), this degrades to `true` — the same tolerant behavior
  /// [purgeOwnedArchive] already had — since that is an environment
  /// limitation, not evidence a known owned file failed to delete.
  static Future<bool> purgeOwnedArchiveStrict() async {
    Directory dir;
    try {
      dir = await _dir();
      if (!await dir.exists()) return true;
    } catch (_) {
      return true;
    }
    var ok = true;
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      try {
        await entity.delete();
      } catch (_) {
        ok = false;
      }
    }
    return ok;
  }

  static String _ownedPrefix(Directory dir) {
    final root = dir.absolute.path;
    return root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
  }
}
