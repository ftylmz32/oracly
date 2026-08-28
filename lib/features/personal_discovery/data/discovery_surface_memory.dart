/// Local surface memory for anti-repetition. Not a user-trait store.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/surfaced_theme_record.dart';

class DiscoverySurfaceMemory {
  DiscoverySurfaceMemory(this._storage);

  static const key = 'discovery_surface_memory_v1';
  static const maxRecords = 40;

  final LocalStorage _storage;

  List<SurfacedThemeRecord> all() {
    final raw = _storage.getStringList(key) ?? const <String>[];
    final items = <SurfacedThemeRecord>[];
    for (final row in raw) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map) continue;
        items.add(
          SurfacedThemeRecord.fromJson(Map<String, dynamic>.from(decoded)),
        );
      } catch (_) {}
    }
    return items..sort((a, b) => b.at.compareTo(a.at));
  }

  Future<void> record(SurfacedThemeRecord entry) async {
    final next = [entry, ...all()].take(maxRecords).toList();
    await _storage.setStringList(
      key,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
