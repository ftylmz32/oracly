/// Coffee JSON → visual + symbolic fields. No invented symbols.
library;

import 'dart:convert';

import '../../../coffee/data/coffee_reading_parser.dart';
import '../../../coffee/models/coffee_symbol.dart';
import '../models/coffee_ai_analysis.dart';

abstract final class CoffeeVisionParser {
  CoffeeVisionParser._();

  static CoffeeAiAnalysis? fromMap(Map<String, dynamic> json) =>
      parse(jsonEncode(json));

  static Map<String, dynamic> toMap(CoffeeAiAnalysis analysis) => {
        'visualObservation': analysis.visualObservation,
        'overall': analysis.overall,
        'love': analysis.love,
        'career': analysis.career,
        'money': analysis.money,
        'nearFuture': analysis.nearFuture,
        'takeaway': analysis.takeaway,
        'symbols': [
          for (final symbol in analysis.symbols) symbol.toJson(),
        ],
      };

  static CoffeeAiAnalysis? parse(String raw) {
    final reading = CoffeeReadingParser.parse(
      raw,
      id: 'parse_only',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    if (reading == null) return null;
    if (reading.overall.trim().isEmpty && reading.takeaway.trim().isEmpty) {
      return null;
    }
    return CoffeeAiAnalysis(
      visualObservation: reading.visualObservation,
      overall: reading.overall,
      love: reading.love,
      career: reading.career,
      money: reading.money,
      nearFuture: reading.nearFuture,
      takeaway: reading.takeaway,
      symbols: [
        for (final symbol in reading.symbols)
          if (symbol.name.trim().isNotEmpty) symbol,
      ],
    );
  }

  static List<CoffeeSymbol> namedOnly(List<CoffeeSymbol> symbols) => [
        for (final symbol in symbols)
          if (symbol.name.trim().isNotEmpty) symbol,
      ];
}
