/// Dream MODEL B — stable attempt id for one narrative submit + retries.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/datasources/storage_result.dart';
import '../../gems/services/paid_ai_operation_id.dart';

/// Survives timeout/retry/app kill for the same narrative; cleared on success
/// or explicit new-dream reset. Account wipe and discovery clear remove
/// [key]. Only a SHA-256 digest of the narrative is stored — never its text.
class DreamAttemptStore {
  DreamAttemptStore(this._storage);

  static const key = 'dream_analysis_attempt_v1';
  static const _digestPrefix = 'sha256:';

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
    if (existing != null && !_isDigest(existing.fp)) {
      // Legacy rows held the readable narrative — drop before re-minting.
      await clear();
    }
    final id = PaidAiOperationId.create('dream');
    await _storage
        .setString(key, jsonEncode({'fp': fp, 'id': id}))
        .requireDurable(key);
    return id;
  }

  Future<void> clear() => _storage.remove(key).requireDurable(key);

  static String fingerprint(String narrative) {
    final normalized = narrative.trim().toLowerCase();
    final digest = sha256.convert(utf8.encode('dream\u0000$normalized'));
    return '$_digestPrefix$digest';
  }

  static bool _isDigest(String fp) =>
      fp.startsWith(_digestPrefix) &&
      fp.length == _digestPrefix.length + 64;

  ({String fp, String id})? _read() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final fp = map['fp'];
      final id = map['id'];
      if (fp is! String || id is! String) return (fp: '', id: '');
      return (fp: fp, id: id);
    } catch (_) {
      return (fp: '', id: '');
    }
  }
}
