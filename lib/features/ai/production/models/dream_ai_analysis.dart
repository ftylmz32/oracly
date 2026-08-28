/// Structured dream AI output — all fields required after validation.
library;

class DreamAiAnalysis {
  const DreamAiAnalysis({
    required this.summary,
    required this.symbols,
    required this.emotionalTheme,
    required this.interpretation,
    required this.dailyLifeReflection,
    required this.conclusion,
  });

  final String summary;
  final List<String> symbols;
  final String emotionalTheme;
  final String interpretation;
  final String dailyLifeReflection;
  final String conclusion;
}
