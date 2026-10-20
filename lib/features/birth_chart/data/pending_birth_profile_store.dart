/// Birth answers given before a local owner existed (offline first launch).
///
/// Saved only when the chart write failed for lack of an owner, and adopted
/// once by the next chart read that has one. Cleared by the account wipe,
/// so a later account on this device never inherits it.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/birth_profile.dart';

class PendingBirthProfileStore {
  PendingBirthProfileStore(this._storage);

  static const storageKey = 'birth_profile_pending_owner';

  final LocalStorage _storage;

  BirthProfile? read() {
    final raw = _storage.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return BirthProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(BirthProfile profile) =>
      _storage.setString(storageKey, jsonEncode(profile.toJson()));

  Future<void> clear() => _storage.remove(storageKey);
}
