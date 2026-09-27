/// Local version chains — one row per reading root id.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../../data/datasources/storage_result.dart';
import '../models/reading_version_group.dart';
import '../models/reading_version_kind.dart';

class ReadingVersionStore {
  ReadingVersionStore(this._storage);

  static const key = 'or_reading_versions_v1';

  final LocalStorage _storage;

  ReadingVersionGroup? byRootId(String rootId) {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final row = map[rootId];
      if (row is! Map<String, dynamic>) return null;
      return ReadingVersionGroup.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  /// Durably persists [group]. A `false` SharedPreferences write is failure.
  Future<void> save(ReadingVersionGroup group) async {
    final raw = _storage.getString(key);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[group.rootId] = group.toJson();
    await _storage.setString(key, jsonEncode(map)).requireDurable();
  }

  Future<void> removeRoot(String rootId) =>
      _removeWhere((id, _) => id == rootId);

  /// Removes every chain of [kind], plus any row keyed by [rootIds] even when
  /// that row is malformed. Other kinds' chains are left untouched.
  Future<void> removeKind(
    ReadingVersionKind kind, {
    Set<String> rootIds = const {},
  }) {
    return _removeWhere(
      (id, row) =>
          rootIds.contains(id) || (row is Map && row['kind'] == kind.name),
    );
  }

  /// An unparseable blob is unreadable for every kind ([byRootId] already
  /// returns null for all of them), so it is removed rather than left behind
  /// holding content the user asked to clear.
  Future<void> _removeWhere(bool Function(String id, Object? row) test) async {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return;
    Map<String, dynamic> map;
    try {
      map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      await _storage.remove(key).requireDurable(key);
      return;
    }
    final before = map.length;
    map.removeWhere(test);
    if (map.length == before) return;
    await _storage.setString(key, jsonEncode(map)).requireDurable(key);
  }
}
