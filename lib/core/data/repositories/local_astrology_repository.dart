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
    return raw
        .map((e) =>
            AstrologyRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> save(AstrologyRecord record) async {
    final history = await getHistory();
    await _storage.setStringList(
      _historyKey,
      [
        ...history.map((e) => jsonEncode(e.toJson())),
        jsonEncode(record.toJson()),
      ],
    );
  }

  @override
  Future<void> sync() async {}
}
