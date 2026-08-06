/// OR-1140 — Dream reading domain model.
library;

import '../core/oracle_engine_type.dart';

class DreamSymbolMatch {
  const DreamSymbolMatch({
    required this.token,
    required this.category,
    required this.confidence,
  });

  final String token;
  final DreamSymbolCategory category;
  final double confidence;
}

class DreamReading {
  const DreamReading({
    required this.id,
    required this.rawText,
    required this.symbols,
    required this.createdAt,
    this.emotions = const [],
  });

  final String id;
  final String rawText;
  final List<DreamSymbolMatch> symbols;
  final List<String> emotions;
  final DateTime createdAt;

  Map<String, dynamic> toFacts() => {
        'id': id,
        'textLength': rawText.length,
        'symbolCount': symbols.length,
        'categories': symbols.map((s) => s.category.name).toSet().toList(),
        'emotions': emotions,
      };
}
