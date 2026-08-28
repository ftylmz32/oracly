/// Local profile photo — copied into app documents. Never sent to AI.
library;

import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/data/datasources/local_storage.dart';

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
    final dest = File('${dir.path}/${filePrefix}_$mark.jpg');
    await File(sourcePath).copy(dest.path);
    await storage.setString(key, dest.path);
    if (previous != null && previous != dest.path) {
      await _deleteQuietly(previous);
    }
  }

  static Future<void> clear(LocalStorage storage) async {
    final stored = storage.getString(key);
    await storage.remove(key);
    await _deleteQuietly(stored);
  }

  static Future<void> _deleteQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}

final profilePhotoEpochProvider = StateProvider<int>((ref) => 0);

final profilePhotoProvider = Provider<ImageProvider?>((ref) {
  ref.watch(profilePhotoEpochProvider);
  return ProfilePhotoStore.imageOf(ref.watch(localStorageProvider));
});
