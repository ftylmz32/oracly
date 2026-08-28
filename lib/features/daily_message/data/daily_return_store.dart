/// Persists today's snapshot so the same day never regenerates.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/daily_message.dart';

class DailyReturnStore {
  DailyReturnStore(this._storage);

  static const todayKey = 'daily_return_today_v1';
  static const previousKey = 'daily_return_previous_v1';
  static const historyKey = 'daily_return_history_v1';

  final LocalStorage _storage;

  DailyMessage? readToday(DateTime day) {
    final current = _read(todayKey);
    if (current == null) return null;
    if (!_sameDay(current.day, day)) return null;
    return current;
  }

  DailyMessage? readPrevious(DateTime day) {
    final current = _read(todayKey);
    if (current != null && !_sameDay(current.day, day)) return current;
    return _read(previousKey);
  }

  List<DailyMessage> snapshots(DateTime day) {
    final today = readToday(day);
    final previous = readPrevious(day);
    return [
      ?today,
      if (previous != null &&
          (today == null || previous.dateKey != today.dateKey))
        previous,
    ];
  }

  List<String> historyTexts() {
    final raw = _storage.getString(historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> commit(DailyMessage next) async {
    final existing = _read(todayKey);
    if (existing != null && _sameDay(existing.day, next.day)) return;
    if (existing != null) {
      await _storage.setString(previousKey, jsonEncode(existing.toJson()));
    }
    await _storage.setString(todayKey, jsonEncode(next.toJson()));
    await _appendHistory(next.text);
  }

  Future<void> _appendHistory(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final next = [...historyTexts().where((item) => item != clean), clean];
    final clipped = next.length <= 7 ? next : next.sublist(next.length - 7);
    await _storage.setString(historyKey, jsonEncode(clipped));
  }

  DailyMessage? _read(String key) {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DailyMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
