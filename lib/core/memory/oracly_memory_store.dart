library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'oracly_memory.dart';

class OraclyMemoryStore {
  OraclyMemoryStore(this._storage);

  static const key = 'oracly_connected_memory_v2';
  static const maxItems = 160;
  final LocalStorage _storage;

  List<OraclyMemory> all() {
    final rows = _storage.getStringList(key) ?? const [];
    final result = <OraclyMemory>[];
    for (final row in rows) {
      try {
        final value = jsonDecode(row);
        if (value is Map) {
          result.add(OraclyMemory.fromJson(Map<String, dynamic>.from(value)));
        }
      } catch (_) {}
    }
    result.sort((a, b) => b.source.occurredAt.compareTo(a.source.occurredAt));
    return result;
  }

  Future<void> upsert(OraclyMemory memory) async {
    final next = <OraclyMemory>[
      memory,
      ...all().where((e) => e.id != memory.id),
    ].take(maxItems).toList();
    await _storage.setStringList(
      key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> remove(String id) => _storage.setStringList(
    key,
    all().where((e) => e.id != id).map((e) => jsonEncode(e.toJson())).toList(),
  );

  Future<void> removeBySource(String sourceId) => _storage.setStringList(
    key,
    all()
        .where((e) => e.source.id != sourceId)
        .map((e) => jsonEncode(e.toJson()))
        .toList(),
  );

  /// Removes connected-memory rows whose source type matches [type] only.
  Future<void> removeByType(OraclyReadingType type) => _storage.setStringList(
    key,
    all()
        .where((e) => e.source.type != type)
        .map((e) => jsonEncode(e.toJson()))
        .toList(),
  );

  Future<void> clear() => _storage.remove(key);
}
