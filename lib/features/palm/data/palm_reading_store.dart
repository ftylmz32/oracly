/// Local palm-reading persistence — JSON + app-owned image path.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';
import '../services/palm_image_archive.dart';

class PalmReadingStore {
  PalmReadingStore(this._storage);

  static const key = 'palm_readings';

  final LocalStorage _storage;

  List<PalmReading> all() {
    final raw = _storage.getStringList(key) ?? const <String>[];
    return [
      for (final row in raw) _fromJson(jsonDecode(row) as Map<String, dynamic>),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  PalmReading? byId(String id) {
    for (final item in all()) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Persist reading with its app-owned image path (never strip by default).
  Future<void> save(PalmReading reading) async {
    final next = [
      for (final item in all())
        if (item.id != reading.id) item,
      reading,
    ];
    await _storage.setStringList(
      key,
      next.map(_toJson).toList(),
    );
  }

  Future<void> delete(String id) async {
    final existing = byId(id);
    final next = [for (final item in all()) if (item.id != id) item];
    await _storage.setStringList(key, next.map(_toJson).toList());
    await PalmImageArchive.deleteIfOwned(existing?.imagePath);
  }

  String _toJson(PalmReading reading) => jsonEncode({
        'id': reading.id,
        'createdAt': reading.createdAt.toIso8601String(),
        'hand': reading.hand.name,
        'overall': reading.overall,
        'lifeLine': reading.lifeLine,
        'headLine': reading.headLine,
        'heartLine': reading.heartLine,
        'fateLine': reading.fateLine,
        'takeaway': reading.takeaway,
        'symbols': reading.symbols,
        'themes': reading.themes,
        if (reading.imagePath != null) 'imagePath': reading.imagePath,
      });

  PalmReading _fromJson(Map<String, dynamic> json) {
    return PalmReading(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      hand: json['hand'] == 'left' ? PalmHand.left : PalmHand.right,
      overall: json['overall'] as String? ?? '',
      lifeLine: json['lifeLine'] as String? ?? '',
      headLine: json['headLine'] as String? ?? '',
      heartLine: json['heartLine'] as String? ?? '',
      fateLine: json['fateLine'] as String? ?? '',
      takeaway: json['takeaway'] as String? ?? '',
      symbols: _strings(json['symbols']),
      themes: _strings(json['themes']),
      imagePath: json['imagePath'] as String?,
    );
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
