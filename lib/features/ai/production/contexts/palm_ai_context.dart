part of 'reading_ai_context.dart';

final class PalmAiContext extends ReadingAiContext {
  const PalmAiContext({
    required this.sessionId,
    required this.overall,
    this.takeaway,
    this.handLabel,
    this.heartLine,
    this.headLine,
    this.lifeLine,
    this.fateLine,
    this.symbols = const [],
    this.themes = const [],
    this.fullInterpretation,
  });

  final String sessionId;
  final String overall;
  final String? takeaway;
  final String? handLabel;
  final String? heartLine;
  final String? headLine;
  final String? lifeLine;
  final String? fateLine;
  final List<String> symbols;
  final List<String> themes;
  final String? fullInterpretation;

  @override
  String get kindId => 'palm';
}
