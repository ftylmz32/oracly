/// RC-009 — Reads ritual history from existing daily ritual storage keys.
library;

import '../../data/datasources/local_storage.dart';
import '../domain/models/ritual_history_entry.dart';

/// Read-only adapter over [DailyRitualService] key layout — no flow changes.
class RitualHistoryReader {
  RitualHistoryReader(this._storage);

  static const reflectionPrefix = 'daily_ritual_reflection_';
  static const cardPrefix = 'daily_ritual_card_';
  static const thoughtPrefix = 'daily_ritual_thought_';

  final LocalStorage _storage;

  List<RitualHistoryEntry> readAll() {
    final dates = <String>{};
    for (final key in _storage.keys) {
      if (key.startsWith(reflectionPrefix)) {
        dates.add(key.substring(reflectionPrefix.length));
      } else if (key.startsWith(cardPrefix)) {
        dates.add(key.substring(cardPrefix.length));
      } else if (key.startsWith(thoughtPrefix)) {
        dates.add(key.substring(thoughtPrefix.length));
      }
    }

    final entries = <RitualHistoryEntry>[];
    for (final dateKey in dates) {
      final parsed = _parseDateKey(dateKey);
      if (parsed == null) continue;

      entries.add(
        RitualHistoryEntry(
          date: parsed,
          reflectionRead:
              _storage.getBool('$reflectionPrefix$dateKey') ?? false,
          cardDrawn: _storage.getBool('$cardPrefix$dateKey') ?? false,
          personalThought: _storage.getString('$thoughtPrefix$dateKey'),
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.where((entry) => entry.hasEngagement).toList();
  }

  DateTime? _parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
