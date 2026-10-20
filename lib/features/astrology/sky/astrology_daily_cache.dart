/// Today's personal astrology reading for the signed-in owner.
///
/// One slot only: owner + operation id (day and calculated facts) must both
/// match, so reopening the same day shows the same text, a new day or new
/// birth data writes a new one, and another account never sees it. The key
/// is cleared by the account wipe.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';

class AstrologyDailyCache {
  AstrologyDailyCache(this._storage);

  static const storageKey = 'astrology_daily_ai_v1';

  final LocalStorage _storage;

  Map<String, String>? read({
    required String ownerId,
    required String operationId,
  }) {
    final raw = _storage.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      if (decoded['owner'] != ownerId || decoded['op'] != operationId) {
        return null;
      }
      final fields = decoded['fields'];
      if (fields is! Map) return null;
      return {
        for (final e in fields.entries)
          if (e.key is String && e.value is String)
            e.key as String: e.value as String,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required String ownerId,
    required String operationId,
    required Map<String, String> fields,
  }) =>
      _storage.setString(
        storageKey,
        jsonEncode({'owner': ownerId, 'op': operationId, 'fields': fields}),
      );
}
