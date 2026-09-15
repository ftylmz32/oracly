/// OR-1130 — Local dream repository with offline cache.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../../domain/models/dream_record.dart';
import '../../domain/repositories/dream_repository.dart';
import '../../memory/oracly_memory_factory.dart';
import '../../memory/oracly_memory_store.dart';

class LocalDreamRepository implements DreamRepository {
  LocalDreamRepository(this._storage, {this._memory});

  static const _key = 'dream_records';

  final LocalStorage _storage;
  final OraclyMemoryStore? _memory;

  @override
  Future<List<DreamRecord>> getAll() async {
    final raw = _storage.getStringList(_key);
    if (raw == null) return [];
    final items = <DreamRecord>[];
    for (final row in raw) {
      final record = _tryParse(row);
      if (record != null) items.add(record);
    }
    return items;
  }

  static DreamRecord? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return DreamRecord.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DreamRecord?> getById(String id) async {
    final all = await getAll();
    for (final record in all) {
      if (record.id == id) return record;
    }
    return null;
  }

  @override
  Future<void> save(DreamRecord record) async {
    final all = await getAll();
    final updated = [
      for (final r in all)
        if (r.id != record.id) r,
      record,
    ];
    await _storage.setStringList(
      _key,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
    try {
      await _memory?.upsert(OraclyMemoryFactory.dream(record));
    } catch (_) {
      // The feature record is authoritative; connected memory is optional.
    }
  }

  @override
  Future<void> delete(String id) async {
    final all = await getAll();
    await _storage.setStringList(
      _key,
      all.where((e) => e.id != id).map((e) => jsonEncode(e.toJson())).toList(),
    );
    try {
      await _memory?.removeBySource(id);
    } catch (_) {
      // Source deletion must succeed even when the index is unavailable.
    }
  }

  @override
  Future<void> sync() async {}
}
