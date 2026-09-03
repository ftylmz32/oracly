/// RC-009 — Lightweight index metadata for future incremental intelligence.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../domain/models/intelligence_facet_counts.dart';

class IntelligenceIndexMeta {
  const IntelligenceIndexMeta({
    required this.schemaVersion,
    required this.builtAt,
    required this.counts,
  });

  final int schemaVersion;
  final DateTime builtAt;
  final IntelligenceFacetCounts counts;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'builtAt': builtAt.toIso8601String(),
        'counts': {
          'readings': counts.readings,
          'favoriteCards': counts.favoriteCards,
          'recurringThemes': counts.recurringThemes,
          'reflections': counts.reflections,
          'conversations': counts.conversations,
          'ritualDays': counts.ritualDays,
        },
      };

  factory IntelligenceIndexMeta.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['counts'] as Map<String, dynamic>? ?? {};
    return IntelligenceIndexMeta(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      builtAt: DateTime.tryParse(json['builtAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      counts: IntelligenceFacetCounts(
        readings: rawCounts['readings'] as int? ?? 0,
        favoriteCards: rawCounts['favoriteCards'] as int? ?? 0,
        recurringThemes: rawCounts['recurringThemes'] as int? ?? 0,
        reflections: rawCounts['reflections'] as int? ?? 0,
        conversations: rawCounts['conversations'] as int? ?? 0,
        ritualDays: rawCounts['ritualDays'] as int? ?? 0,
      ),
    );
  }
}

/// Persists last-built snapshot metadata — not user-facing.
class IntelligenceIndexStore {
  IntelligenceIndexStore(this._storage);

  static const key = 'or_intelligence_index';

  final LocalStorage _storage;

  IntelligenceIndexMeta? load() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return IntelligenceIndexMeta.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(IntelligenceIndexMeta meta) async {
    await _storage.setString(key, jsonEncode(meta.toJson()));
  }
}
