/// OR-1000 — Tarot module route names.
library;

/// Named routes for the Tarot ritual navigator.
abstract final class TarotRoutes {
  TarotRoutes._();

  static const String home = '/tarot';
  static const String deckSelection = '/tarot/deck';
  static const String shuffle = '/tarot/shuffle';
  static const String cardSelection = '/tarot/select';
  static const String cardReveal = '/tarot/reveal';
  static const String reading = '/tarot/reading';
  static const String cardDetail = '/tarot/card';
  static const String history = '/tarot/history';
  static const String premium = '/tarot/premium';
}
