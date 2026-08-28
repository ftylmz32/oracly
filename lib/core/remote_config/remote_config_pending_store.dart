/// Persists staged remote config for the next session — metadata only.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'remote_config_defaults.dart';
import 'remote_config_snapshot.dart';
import 'remote_config_validator.dart';

class RemoteConfigPendingStore {
  RemoteConfigPendingStore(this._storage);

  static const key = 'or_remote_config_pending_v1';

  final LocalStorage _storage;

  RemoteConfigSnapshot? load() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, Object?>.from(decoded);
      final validation = RemoteConfigValidator.validate(map);
      if (!validation.isAccepted) return null;
      return validation.snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(RemoteConfigSnapshot snapshot) async {
    if (identical(snapshot, RemoteConfigDefaults.snapshot)) {
      await clear();
      return;
    }
    await _storage.setString(key, jsonEncode(snapshot.toPersistedJson()));
  }

  Future<void> clear() => _storage.remove(key);
}
