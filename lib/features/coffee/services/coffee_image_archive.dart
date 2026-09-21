/// Persist coffee cup images in app-private storage for saved readings.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../privacy/services/archive_path_kind.dart';

abstract final class CoffeeImageArchive {
  CoffeeImageArchive._();

  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}coffee_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> persist({
    required String readingId,
    required String sourcePath,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw StateError('coffee source missing');
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

  /// Tri-state ownership for STRICT account-boundary cleanup.
  /// [ArchivePathKind.unknown] must never be treated as "external success".
  static Future<ArchivePathKind> classifyPath(String path) async {
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return ArchivePathKind.notOwned;
      final root = _ownedPrefix(await _dir());
      final absolute = File(trimmed).absolute.path;
      return absolute.startsWith(root)
          ? ArchivePathKind.owned
          : ArchivePathKind.notOwned;
    } catch (_) {
      return ArchivePathKind.unknown;
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
  /// Returns `false` when an OWNED delete fails OR ownership cannot be
  /// determined ([ArchivePathKind.unknown]). Proven non-owned paths are
  /// ignored (`true`).
  static Future<bool> deleteIfOwnedStrict(String? path) async {
    if (path == null || path.trim().isEmpty) return true;
    final kind = await classifyPath(path);
    if (kind == ArchivePathKind.notOwned) return true;
    if (kind == ArchivePathKind.unknown) return false;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Remove every file under the coffee archive directory.
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