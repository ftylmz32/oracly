/// EPIC-011 — Gentle daily ritual persistence (no streaks).
library;

import '../../../core/data/datasources/local_storage.dart';
import '../models/daily_ritual_day.dart';

/// Date-keyed ritual state — private, never scored.
class DailyRitualService {
  DailyRitualService(this._storage);

  final LocalStorage _storage;

  static String dateKey([DateTime? day]) {
    final d = day ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _reflectionKey(String key) => 'daily_ritual_reflection_$key';
  String _cardKey(String key) => 'daily_ritual_card_$key';
  String _thoughtKey(String key) => 'daily_ritual_thought_$key';

  DailyRitualDay loadToday([DateTime? day]) {
    final key = dateKey(day);
    return DailyRitualDay(
      reflectionRead: _storage.getBool(_reflectionKey(key)) ?? false,
      cardDrawn: _storage.getBool(_cardKey(key)) ?? false,
      personalThought: _storage.getString(_thoughtKey(key)),
    );
  }

  Future<void> markReflectionRead([DateTime? day]) async {
    final key = dateKey(day);
    await _storage.setBool(_reflectionKey(key), true);
  }

  Future<void> markCardDrawn([DateTime? day]) async {
    final key = dateKey(day);
    await _storage.setBool(_cardKey(key), true);
  }

  Future<void> saveThought(String thought, [DateTime? day]) async {
    final key = dateKey(day);
    final trimmed = thought.trim();
    if (trimmed.isEmpty) {
      await _storage.remove(_thoughtKey(key));
      return;
    }
    await _storage.setString(_thoughtKey(key), trimmed);
  }
}
