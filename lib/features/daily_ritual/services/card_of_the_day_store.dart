/// Persists today's card identity — same day never redraws.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/card_of_the_day.dart';
import 'daily_ritual_service.dart';

class CardOfTheDayStore {
  CardOfTheDayStore(this._storage);

  static const storageKey = 'card_of_the_day_v1';

  final LocalStorage _storage;

  CardOfTheDay? readToday([DateTime? day]) {
    final current = _read();
    if (current == null) return null;
    final key = DailyRitualService.dateKey(day);
    if (current.dateKey != key) return null;
    return current;
  }

  /// Writes only when no card exists for [card]'s day.
  Future<void> commit(CardOfTheDay card) async {
    final existing = readToday(card.day);
    if (existing != null) return;
    await _storage.setString(storageKey, jsonEncode(card.toJson()));
  }

  CardOfTheDay? _read() {
    final raw = _storage.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CardOfTheDay.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
