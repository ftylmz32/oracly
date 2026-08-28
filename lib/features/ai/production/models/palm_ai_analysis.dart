/// Palm vision result — symbolic lines only, never medical.
library;

import '../../../palm/models/palm_hand.dart';
import '../../../palm/models/palm_reading.dart';

class PalmAiAnalysis {
  const PalmAiAnalysis({
    required this.overall,
    this.lifeLine = '',
    this.headLine = '',
    this.heartLine = '',
    this.fateLine = '',
    this.takeaway = '',
    this.symbols = const [],
    this.themes = const [],
  });

  final String overall;
  final String lifeLine;
  final String headLine;
  final String heartLine;
  final String fateLine;
  final String takeaway;
  final List<String> symbols;
  final List<String> themes;

  PalmReading toReading({
    required String id,
    required DateTime createdAt,
    required PalmHand hand,
    String? imagePath,
  }) {
    return PalmReading(
      id: id,
      createdAt: createdAt,
      hand: hand,
      overall: overall,
      lifeLine: lifeLine,
      headLine: headLine,
      heartLine: heartLine,
      fateLine: fateLine,
      takeaway: takeaway,
      symbols: symbols,
      themes: themes,
      imagePath: imagePath,
    );
  }
}
