/// Persists one daily personal observation — never auto-written without resolve.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/daily_personal_observation_record.dart';

class DailyPersonalObservationStore {
  DailyPersonalObservationStore(this._storage);

  static const key = 'daily_personal_observation_v1';

  final LocalStorage _storage;

  DailyPersonalObservationRecord? read() {
    final raw = _storage.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DailyPersonalObservationRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(DailyPersonalObservationRecord record) async {
    await _storage.setString(key, jsonEncode(record.toJson()));
  }

  void writeNow(DailyPersonalObservationRecord record) {
    // ignore: discarded_futures
    write(record);
  }
}
