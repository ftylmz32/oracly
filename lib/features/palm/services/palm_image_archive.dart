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

  /// Delete archived image when reading is removed — never touch external paths.
  static Future<void> deleteIfOwned(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    final owned = (await _dir()).path;
    if (!file.absolute.path.startsWith(Directory(owned).absolute.path)) {
      return;
    }
    try {
      await file.delete();
    } catch (_) {}
  }
}
