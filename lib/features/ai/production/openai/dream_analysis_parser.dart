/// Validates structured dream JSON — invalid → null, never a fake reading.
library;

import 'dart:convert';

import '../models/dream_ai_analysis.dart';

abstract final class DreamAnalysisParser {
  DreamAnalysisParser._();

  static DreamAiAnalysis? parse(String raw) {
    final json = _extractJson(raw);
    if (json == null) return null;
    return fromMap(json);
  }

  static DreamAiAnalysis? fromMap(Map<String, dynamic> json) {
    final summary = _text(json, const ['ozet', 'özet', 'summary']);
    final theme = _text(json, const [
      'duygusalTema',
      'emotionalTheme',
      'duygu',
    ]);
    final interpretation = _text(json, const ['yorum', 'interpretation']);
    final daily = _text(json, const [
      'gunlukYansi',
      'günlükYansıma',
      'dailyLifeReflection',
      'yansi',
    ]);
    final conclusion = _text(json, const ['sonuc', 'sonuç', 'conclusion']);
    if (summary.isEmpty ||
        theme.isEmpty ||
        interpretation.isEmpty ||
        daily.isEmpty ||
        conclusion.isEmpty) {
      return null;
    }
    return DreamAiAnalysis(
      summary: summary,
      symbols: _stringList(json['semboller'] ?? json['symbols']),
      emotionalTheme: theme,
      interpretation: interpretation,
      dailyLifeReflection: daily,
      conclusion: conclusion,
    );
  }

  static Map<String, dynamic> toMap(DreamAiAnalysis analysis) => {
        'summary': analysis.summary,
        'symbols': analysis.symbols,
        'emotionalTheme': analysis.emotionalTheme,
        'interpretation': analysis.interpretation,
        'dailyLifeReflection': analysis.dailyLifeReflection,
        'conclusion': analysis.conclusion,
      };

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
      if (value is String && value.trim().length >= 8) return value.trim();
    }
    return '';
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
