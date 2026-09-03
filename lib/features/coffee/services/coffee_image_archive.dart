/// Persist coffee cup images in app-private storage for saved readings.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

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

  static String _ownedPrefix(Directory dir) {
    final root = dir.absolute.path;
    return root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
  }
}