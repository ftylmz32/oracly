/// Local coffee-reading persistence.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/coffee_reading.dart';

class CoffeeReadingStore {
  CoffeeReadingStore(this._storage);

  static const key = 'coffee_readings';

  final LocalStorage _storage;

  List<CoffeeReading> all() {
    final raw = _storage.getStringList(key) ?? const <String>[];
    final items = <CoffeeReading>[];
    for (final row in raw) {
      final reading = _tryParse(row);
      if (reading != null) items.add(reading);
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static CoffeeReading? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CoffeeReading.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  CoffeeReading? byId(String id) {
    for (final reading in all()) {
      if (reading.id == id) return reading;
    }
    return null;
  }

  Future<void> save(CoffeeReading reading) async {
    final next = [
      for (final item in all())
        if (item.id != reading.id) item,
      reading,
    ];
    await _storage.setStringList(
      key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
