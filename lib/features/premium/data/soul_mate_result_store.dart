/// Local Soulmate result — portrait file + JSON metadata.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/data/datasources/local_storage.dart';
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
    );
    await storage.setString(metaKey, jsonEncode(saved.toJson()));
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

  static Future<void> _deleteQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}