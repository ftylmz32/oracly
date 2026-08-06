/// OR-1100 — Mock history repository with local persistence.
library;

import 'dart:convert';

import '../../domain/models/reading.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local_storage.dart';

class MockHistoryRepository implements HistoryRepository {
  MockHistoryRepository(this._storage);

  final LocalStorage _storage;
  static const _key = 'or_reading_history';

  @override
  Future<List<ReadingModel>> getReadings() async {
    final raw = _storage.getStringList(_key) ?? [];
    return raw
        .map((e) => ReadingModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveReading(ReadingModel reading) async {
    final current = await getReadings();
    final encoded = jsonEncode(reading.toJson());
    final list = [
      encoded,
      ...current
          .where((r) => r.id != reading.id)
          .map((r) => jsonEncode(r.toJson())),
    ];
    await _storage.setStringList(_key, list);
  }

  @override
  Future<void> deleteReading(String id) async {
    final current = await getReadings();
    await _storage.setStringList(
      _key,
      current.where((r) => r.id != id).map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  @override
  Future<void> clearAll() async => _storage.setStringList(_key, []);
}
