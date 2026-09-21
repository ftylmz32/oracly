/// Local Soulmate result — portrait file + JSON metadata.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/auth/managed_file_path.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/datasources/storage_result.dart';
import '../models/soul_mate_saved_result.dart';

abstract final class SoulMateResultStore {
  SoulMateResultStore._();

  static const metaKey = 'soulmate_latest';
  static const portraitPrefix = 'oracly_soulmate_portrait';

  static Future<SoulMateSavedResult?> readMeta(LocalStorage storage) async {
    final raw = storage.getString(metaKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return SoulMateSavedResult.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<List<int>?> readPortraitBytes(String path) async {
    if (path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  static Future<SoulMateSavedResult?> save({
    required LocalStorage storage,
    required SoulMateSavedResult record,
    required List<int> portraitBytes,
    Directory? documents,
  }) async {
    if (portraitBytes.isEmpty) return null;
    final previous = await readMeta(storage);
    final dir = documents ?? await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/${portraitPrefix}_${record.id}.jpg');
    await dest.writeAsBytes(portraitBytes, flush: true);
    final saved = SoulMateSavedResult(
      id: record.id,
      createdAt: record.createdAt,
      name: record.name,
      birthDate: record.birthDate,
      gender: record.gender,
      intention: record.intention,
      portraitPath: dest.path,
      parts: record.parts,
      localeCode: record.localeCode,
      identity: record.identity,
    );
    try {
      await storage
          .setString(metaKey, jsonEncode(saved.toJson()))
          .requireDurable();
    } catch (_) {
      await _deleteQuietly(dest.path);
      rethrow;
    }
    if (previous != null && previous.portraitPath != dest.path) {
      await _deleteQuietly(previous.portraitPath);
    }
    return saved;
  }

  static Future<void> clear(LocalStorage storage) async {
    final previous = await readMeta(storage);
    await storage.remove(metaKey);
    await _deleteQuietly(previous?.portraitPath);
  }

  /// Account-boundary wipe — tri-state ownership (see [ManagedPathKind]).
  static Future<void> clearStrict(LocalStorage storage) async {
    final previous = await readMeta(storage);
    final path = previous?.portraitPath;
    if (path != null && path.isNotEmpty) {
      final kind = await ManagedFilePath.classify(
        path,
        filePrefix: portraitPrefix,
      );
      switch (kind) {
        case ManagedPathKind.managed:
          if (!await _deleteStrict(path)) {
            throw StateError('soulmate portrait file delete failed');
          }
        case ManagedPathKind.notManaged:
          break;
        case ManagedPathKind.unknown:
          throw StateError('soulmate portrait ownership unknown');
      }
    }
    if (!await storage.remove(metaKey)) {
      throw StateError('soulmate meta key removal failed');
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
