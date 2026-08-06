/// OR-1110 — Dream analysis AI prompt model.
library;

class DreamPrompt {
  const DreamPrompt({
    required this.dreamText,
    this.emotions = const [],
    this.symbols = const [],
    this.locale = 'tr',
    this.personality = 'mystical',
  });

  final String dreamText;
  final List<String> emotions;
  final List<String> symbols;
  final String locale;
  final String personality;

  Map<String, dynamic> toContext() => {
        'domain': 'dream',
        'dreamText': dreamText,
        'emotions': emotions,
        'symbols': symbols,
        'locale': locale,
        'personality': personality,
      };
}
