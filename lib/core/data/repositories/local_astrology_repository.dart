/// OR-1130 — Local astrology repository.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../../domain/models/astrology_record.dart';
import '../../domain/repositories/astrology_repository.dart';

class LocalAstrologyRepository implements AstrologyRepository {
  LocalAstrologyRepository(this._storage);

  static const _historyKey = 'astrology_history';

  final LocalStorage _storage;

  @override
  Future<AstrologyRecord?> getDailyHoroscope(String sign) async {
    return AstrologyRecord(
      id: 'daily_${sign}_${DateTime.now().toIso8601String().substring(0, 10)}',
      sign: sign,
      horoscope:
          '$sign burcunda bugün tablo net: acele etmek yerine tek görünür '
          'adım daha doğru. Kesin gelecek yok; sembolik bir bakış.',
      date: DateTime.now(),
    );
  }

  @override
  Future<List<AstrologyRecord>> getHistory() async {
    final raw = _storage.getStringList(_historyKey);
    if (raw == null) return [];
    final items = <AstrologyRecord>[];
    for (final row in raw) {
      final record = _tryParse(row);
      if (record != null) items.add(record);
    }
    return items;
  }

  static AstrologyRecord? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AstrologyRecord.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AstrologyRecord record) async {
    final history = await getHistory();
    final next = [
      for (final item in history)
        if (item.id != record.id) item,
      record,
    ];
    await _storage.setStringList(
      _historyKey,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> sync() async {}
}
