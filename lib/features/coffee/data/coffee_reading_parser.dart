/// Parses model JSON into a coffee reading — no invented symbols.
library;

import 'dart:convert';

import '../models/coffee_reading.dart';
import '../models/coffee_symbol.dart';

abstract final class CoffeeReadingParser {
  CoffeeReadingParser._();

  static CoffeeReading? parse(
    String raw, {
    required String id,
    required DateTime createdAt,
    String? imagePath,
  }) {
    final json = _extractJson(raw);
    if (json == null) return null;
    final overall = _text(json, const ['genelYorum', 'overall', 'genel']);
    final takeaway = _text(json, const ['sonuc', 'takeaway', 'sonuç']);
    if (overall.isEmpty && takeaway.isEmpty) return null;
    return CoffeeReading(
      id: id,
      createdAt: createdAt,
      imagePath: imagePath,
      visualObservation: _text(json, const [
        'gorselTespit',
        'görselTespit',
        'visualObservation',
        'visual',
        'detectedVisual',
      ]),
      overall: overall,
      love: _text(json, const ['ask', 'aşk', 'love']),
      career: _text(json, const ['kariyer', 'career']),
      money: _text(json, const ['maddiDurum', 'maddi', 'money']),
      nearFuture: _text(json, const [
        'yakinDonem',
        'yakınDönem',
        'yakinGelecek',
        'yakınGelecek',
        'nearFuture',
      ]),
      takeaway: takeaway,
      symbols: _symbols(json['semboller'] ?? json['symbols']),
    );
  }

  static Map<String, dynamic>? _extractJson(String raw) {
    final trimmed = raw.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(trimmed.substring(start, end + 1));
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static String _text(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static List<CoffeeSymbol> _symbols(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          CoffeeSymbol.fromJson(Map<String, dynamic>.from(item)),
    ].where((s) => s.name.trim().isNotEmpty).toList();
  }
}
