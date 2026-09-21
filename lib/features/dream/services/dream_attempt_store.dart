/// Dream MODEL B — stable attempt id for one narrative submit + retries.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/datasources/storage_result.dart';
import '../../ai/production/ai_request_fingerprint.dart';
import '../../gems/services/paid_ai_operation_id.dart';

/// Survives timeout/retry/app kill for the same narrative; cleared on success
/// or explicit new-dream reset. Account wipe removes [key].
class DreamAttemptStore {
  DreamAttemptStore(this._storage);

  static const key = 'dream_analysis_attempt_v1';

  final LocalStorage _storage;

  /// Same narrative → same attempt id. Changed narrative → new id.
  Future<String> resolveId(String narrative) async {
    final fp = fingerprint(narrative);
    final existing = _read();
    if (existing != null &&
        existing.fp == fp &&
        existing.id.isNotEmpty) {
      return existing.id;
    }
    final id = PaidAiOperationId.create('dream');
    await _storage
        .setString(key, jsonEncode({'fp': fp, 'id': id}))
        .requireDurable(key);
    return id;
  }

  Future<void> clear() => _storage.remove(key).requireDurable(key);

  static String fingerprint(String narrative) =>
      AiRequestFingerprint.text('dream', narrative.trim().toLowerCase());

  ({String fp, String id})? _read() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final fp = map['fp'];
      final id = map['id'];
      if (fp is! String || id is! String) return null;
      return (fp: fp, id: id);
    } catch (_) {
      return null;
    }
  }
}
