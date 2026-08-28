/// SPRINT-002 — Local birth chart storage.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../../domain/models/birth_chart_record.dart';
import '../../domain/repositories/birth_chart_repository.dart';

class LocalBirthChartRepository implements BirthChartRepository {
  LocalBirthChartRepository(this._storage);

  static const _key = 'birth_chart_latest';

  final LocalStorage _storage;

  @override
  Future<BirthChartRecord?> getLatest() async {
    final raw = _storage.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return BirthChartRecord.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(BirthChartRecord record) async {
    await _storage.setString(_key, jsonEncode(record.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final current = await getLatest();
    if (current?.id == id) {
      await clearLatest();
    }
  }

  @override
  Future<void> clearLatest() async {
    await _storage.remove(_key);
  }
}
