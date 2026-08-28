/// A persisted palm reading — only stored after a real analysis.
library;

import 'palm_hand.dart';

class PalmReading {
  const PalmReading({
    required this.id,
    required this.createdAt,
    required this.hand,
    required this.overall,
    this.lifeLine = '',
    this.headLine = '',
    this.heartLine = '',
    this.fateLine = '',
    this.takeaway = '',
    this.symbols = const [],
    this.themes = const [],
    this.imagePath,
  });

  final String id;
  final DateTime createdAt;
  final PalmHand hand;
  final String overall;
  final String lifeLine;
  final String headLine;
  final String heartLine;
  final String fateLine;
  final String takeaway;
  final List<String> symbols;
  final List<String> themes;

  /// App-private persisted path only — never gallery/camera temp.
  final String? imagePath;

  String get fullText => [
        overall,
        lifeLine,
        headLine,
        heartLine,
        fateLine,
        takeaway,
        ...symbols,
        ...themes,
      ].join(' ');

  PalmReading copyWith({
    String? overall,
    String? lifeLine,
    String? headLine,
    String? heartLine,
    String? fateLine,
    String? takeaway,
    List<String>? symbols,
    List<String>? themes,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return PalmReading(
      id: id,
      createdAt: createdAt,
      hand: hand,
      overall: overall ?? this.overall,
      lifeLine: lifeLine ?? this.lifeLine,
      headLine: headLine ?? this.headLine,
      heartLine: heartLine ?? this.heartLine,
      fateLine: fateLine ?? this.fateLine,
      takeaway: takeaway ?? this.takeaway,
      symbols: symbols ?? this.symbols,
      themes: themes ?? this.themes,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    );
  }
}
