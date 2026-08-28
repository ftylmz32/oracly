/// Persists [PersonalMemorySummary] — compact JSON only.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../domain/models/personal_memory_summary.dart';
import '../services/personal_memory_privacy.dart';

class PersonalMemoryStore {
  PersonalMemoryStore(this._storage);

  static const key = 'or_personal_memory_v1';
  static const userResetKey = 'or_personal_memory_user_reset_v1';

  final LocalStorage _storage;

  String? blockedFingerprint() {
    final raw = _storage.getString(userResetKey);
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> clearResetBlock() async {
    await _storage.remove(userResetKey);
  }

  Future<void> userReset() async {
    final fingerprint = load().fingerprint;
    if (fingerprint.isNotEmpty) {
      await _storage.setString(userResetKey, fingerprint);
    }
    await clear();
  }

  PersonalMemorySummary load() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return PersonalMemorySummary.empty;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!PersonalMemoryPrivacy.isSafe(json)) {
        return PersonalMemorySummary.empty;
      }
      return PersonalMemorySummary.fromJson(json);
    } catch (_) {
      return PersonalMemorySummary.empty;
    }
  }

  Future<void> save(PersonalMemorySummary summary) async {
    if (!PersonalMemoryPrivacy.isSafe(summary.toJson())) return;
    await _storage.setString(key, jsonEncode(summary.toJson()));
  }

  Future<void> clear() async {
    await _storage.remove(key);
  }
}
