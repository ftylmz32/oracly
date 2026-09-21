/// Local coffee-reading persistence.
library;

import 'dart:convert';

import '../../../core/auth/owned_file_cleanup_journal.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/memory/oracly_memory_factory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../models/coffee_reading.dart';

class CoffeeReadingStore {
  CoffeeReadingStore(this._storage, {OraclyMemoryStore? memory})
      : _memory = memory;

  static const key = 'coffee_readings';

  final LocalStorage _storage;
  final OraclyMemoryStore? _memory;

  List<CoffeeReading> all() {
    final raw = _storage.getStringList(key) ?? const <String>[];
    final items = <CoffeeReading>[];
    for (final row in raw) {
      final reading = _tryParse(row);
      if (reading != null) items.add(reading);
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static CoffeeReading? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CoffeeReading.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  CoffeeReading? byId(String id) {
    for (final reading in all()) {
      if (reading.id == id) return reading;
    }
    return null;
  }

  Future<void> save(CoffeeReading reading) async {
    final next = [
      for (final item in all())
        if (item.id != reading.id) item,
      reading,
    ];
    final ok = await _storage.setStringList(
      key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
    if (!ok) {
      throw StateError('coffee reading metadata write failed');
    }
    // Memory enrichment is reconcilable — reading metadata is the commit point.
    try {
      await _memory?.upsert(OraclyMemoryFactory.coffee(reading));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    final ok = await _storage.setStringList(
      key,
      all().where((e) => e.id != id)
          .map((e) => jsonEncode(e.toJson())).toList(),
    );
    if (!ok) {
      throw StateError('coffee reading metadata delete failed');
    }
    try {
      await _memory?.removeBySource(id);
    } catch (_) {}
  }

  /// Locator for an owned archive that survived a failed metadata commit.
  Future<bool> journalOwnedImagePath(String path) {
    return OwnedFileCleanupJournal.record(_storage, {path});
  }
}
