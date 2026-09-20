/// OR-1100 — Mock history repository with local persistence.
library;

import 'dart:convert';

import '../../domain/models/reading.dart';
import '../../domain/repositories/history_repository.dart';
import '../../history/history_scale_policy.dart';
import '../datasources/local_storage.dart';
import '../../memory/oracly_memory_factory.dart';
import '../../memory/oracly_memory_store.dart';

class MockHistoryRepository implements HistoryRepository {
  MockHistoryRepository(this._storage, {OraclyMemoryStore? memory})
    : _memory = memory;

  final LocalStorage _storage;
  final OraclyMemoryStore? _memory;
  static const _key = 'or_reading_history';

  /// Serializes every mutation (save/delete/clear) onto one queue. Each
  /// mutation is read-modify-write over the SAME encoded list — without
  /// this, two concurrent saves for DIFFERENT reading ids can each read
  /// the same "before" list and one write silently clobbers the other's
  /// entry (last write wins), losing a reading that was never actually
  /// deleted or superseded.
  Future<void> _writeQueue = Future.value();

  Future<T> _enqueueWrite<T>(Future<T> Function() job) {
    final result = _writeQueue.then((_) => job());
    _writeQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<List<ReadingModel>> getReadings() async {
    final raw = _storage.getStringList(_key) ?? [];
    final readings = <ReadingModel>[];
    for (final entry in raw) {
      final reading = _tryParse(entry);
      if (reading != null) readings.add(reading);
    }
    readings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return readings;
  }

  static ReadingModel? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ReadingModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveReading(ReadingModel reading) {
    return _enqueueWrite(() => _saveReadingLocked(reading));
  }

  Future<void> _saveReadingLocked(ReadingModel reading) async {
    final current = await getReadings();
    final encoded = jsonEncode(reading.toJson());
    final list = HistoryScalePolicy.trimEncodedRetention([
      encoded,
      ...current
          .where((r) => r.id != reading.id)
          .map((r) => jsonEncode(r.toJson())),
    ]);
    await _storage.setStringList(_key, list);
    await _memory?.upsert(OraclyMemoryFactory.tarot(reading));
  }

  @override
  Future<void> deleteReading(String id) {
    return _enqueueWrite(() => _deleteReadingLocked(id));
  }

  Future<void> _deleteReadingLocked(String id) async {
    final current = await getReadings();
    await _storage.setStringList(
      _key,
      current
          .where((r) => r.id != id)
          .map((r) => jsonEncode(r.toJson()))
          .toList(),
    );
    await _memory?.removeBySource(id);
  }

  @override
  Future<void> clearAll() {
    return _enqueueWrite(_clearAllLocked);
  }

  Future<void> _clearAllLocked() async {
    final ids = (await getReadings()).map((e) => e.id).toList();
    await _storage.setStringList(_key, []);
    for (final id in ids) await _memory?.removeBySource(id);
  }
}
