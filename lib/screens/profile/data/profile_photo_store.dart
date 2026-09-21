/// Local profile photo — copied into app documents. Never sent to AI.
library;

import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/managed_file_path.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/datasources/storage_result.dart';

abstract final class ProfilePhotoStore {
  ProfilePhotoStore._();

  static const key = 'profile_photo_path';
  static const filePrefix = 'oracly_profile_photo';

  static ImageProvider? imageOf(LocalStorage storage) {
    final path = storage.getString(key);
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  static Future<void> save(
    LocalStorage storage,
    String sourcePath, {
    Directory? documents,
    int? stamp,
  }) async {
    final previous = storage.getString(key);
    final dir = documents ?? await getApplicationDocumentsDirectory();
    final mark = stamp ?? DateTime.now().millisecondsSinceEpoch;
    // Unique candidate even when [stamp] collides with a prior committed file.
    var dest = File('${dir.path}/${filePrefix}_$mark.jpg');
    if (previous != null && previous == dest.path) {
      dest = File(
        '${dir.path}/${filePrefix}_${mark}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
    } else if (dest.existsSync()) {
      dest = File(
        '${dir.path}/${filePrefix}_${mark}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
    }
    await File(sourcePath).copy(dest.path);
    try {
      await storage.setString(key, dest.path).requireDurable();
    } catch (_) {
      // Metadata never committed — delete ONLY the candidate.
      await _deleteQuietly(dest.path);
      rethrow;
    }
    if (previous != null && previous != dest.path) {
      await _deleteQuietly(previous);
    }
  }

  static Future<void> clear(LocalStorage storage) async {
    final stored = storage.getString(key);
    await storage.remove(key);
    await _deleteQuietly(stored);
  }

  /// Account-boundary wipe — tri-state ownership (see [ManagedPathKind]).
  ///
  /// - managed: delete file, then remove metadata
  /// - notManaged: never delete file; metadata may be removed
  /// - unknown: keep file AND metadata; fail for retry
  static Future<void> clearStrict(LocalStorage storage) async {
    final stored = storage.getString(key);
    if (stored != null && stored.isNotEmpty) {
      final kind = await ManagedFilePath.classify(
        stored,
        filePrefix: filePrefix,
      );
      switch (kind) {
        case ManagedPathKind.managed:
          if (!await _deleteStrict(stored)) {
            throw StateError('profile photo file delete failed');
          }
        case ManagedPathKind.notManaged:
          break;
        case ManagedPathKind.unknown:
          throw StateError('profile photo ownership unknown');
      }
    }
    if (!await storage.remove(key)) {
      throw StateError('profile photo key removal failed');
    }
  }

  static Future<void> _deleteQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  static Future<bool> _deleteStrict(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return true;
      file.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final profilePhotoEpochProvider = StateProvider<int>((ref) => 0);

final profilePhotoProvider = Provider<ImageProvider?>((ref) {
  ref.watch(profilePhotoEpochProvider);
  return ProfilePhotoStore.imageOf(ref.watch(localStorageProvider));
});
