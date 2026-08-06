/// OR-1110 — Tarot-specific AI prompt model.
library;

class TarotPrompt {
  const TarotPrompt({
    required this.cardName,
    required this.cardIndex,
    required this.spreadType,
    required this.intention,
    this.isReversed = false,
    this.locale = 'tr',
    this.personality = 'mystical',
  });

  final String cardName;
  final int cardIndex;
  final String spreadType;
  final String intention;
  final bool isReversed;
  final String locale;
  final String personality;

  Map<String, dynamic> toContext() => {
        'domain': 'tarot',
        'cardName': cardName,
        'cardIndex': cardIndex,
        'spreadType': spreadType,
        'intention': intention,
        'isReversed': isReversed,
        'locale': locale,
        'personality': personality,
      };
}
