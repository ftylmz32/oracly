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
    return [
      for (final row in raw)
        CoffeeReading.fromJson(jsonDecode(row) as Map<String, dynamic>),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
