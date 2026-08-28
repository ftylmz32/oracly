/// EPIC-015 — Tracks presence gaps for welcome-back copy.
library;

import '../data/datasources/local_storage.dart';

abstract final class LivingPresenceTracker {
  LivingPresenceTracker._();

  static const _key = 'living_last_presence_at';

  static Future<int?> daysAway(LocalStorage storage, {DateTime? asOf}) async {
    final raw = storage.getString(_key);
    if (raw == null) return null;
    final last = DateTime.tryParse(raw);
    if (last == null) return null;
    final now = asOf ?? DateTime.now();
    return now.difference(last).inDays;
  }

  static Future<void> markPresent(LocalStorage storage, {DateTime? asOf}) {
    final moment = (asOf ?? DateTime.now()).toIso8601String();
    return storage.setString(_key, moment);
  }
}
