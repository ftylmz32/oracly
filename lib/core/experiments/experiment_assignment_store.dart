/// Persists stable experiment assignments until version or experiment ends.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';

class ExperimentAssignmentStore {
  ExperimentAssignmentStore(this._storage);

  static const _key = 'experiment_assignments_v1';

  final LocalStorage _storage;
  final _cache = <String, _Record>{};
  var _loaded = false;

  String? read(String experimentId, int version) {
    _ensureLoaded();
    final record = _cache[experimentId];
    if (record == null || record.version != version) return null;
    return record.variant;
  }

  void remember(String experimentId, int version, String variant) {
    _ensureLoaded();
    _cache[experimentId] = _Record(version: version, variant: variant);
    _persist();
  }

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final version = value['version'];
        final variant = value['variant']?.toString();
        if (variant == null || variant.isEmpty) return;
        if (version is! int) return;
        _cache[key.toString()] = _Record(version: version, variant: variant);
      });
    } catch (_) {}
  }

  void _persist() {
    final payload = {
      for (final entry in _cache.entries)
        entry.key: {
          'version': entry.value.version,
          'variant': entry.value.variant,
        },
    };
    _storage.setString(_key, jsonEncode(payload));
  }
}

class _Record {
  const _Record({required this.version, required this.variant});

  final int version;
  final String variant;
}
