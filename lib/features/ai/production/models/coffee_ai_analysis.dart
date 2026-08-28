/// Coffee vision result — visual detection separate from symbolism.
library;

import '../../../coffee/models/coffee_reading.dart';
import '../../../coffee/models/coffee_symbol.dart';

class CoffeeAiAnalysis {
  const CoffeeAiAnalysis({
    required this.visualObservation,
    required this.overall,
    required this.love,
    required this.career,
    required this.money,
    required this.nearFuture,
    required this.takeaway,
    this.symbols = const [],
  });

  final String visualObservation;
  final String overall;
  final String love;
  final String career;
  final String money;
  final String nearFuture;
  final String takeaway;
  final List<CoffeeSymbol> symbols;

  CoffeeReading toReading({
    required String id,
    required DateTime createdAt,
    String? imagePath,
  }) {
    return CoffeeReading(
      id: id,
      createdAt: createdAt,
      imagePath: imagePath,
      visualObservation: visualObservation,
      overall: overall,
      love: love,
      career: career,
      money: money,
      nearFuture: nearFuture,
      takeaway: takeaway,
      symbols: symbols,
    );
  }
}
