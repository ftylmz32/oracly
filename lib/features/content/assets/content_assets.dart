/// OR-1150 — Content asset path constants.
library;

abstract final class ContentAssets {
  ContentAssets._();

  static const String tarotRoot = 'lib/assets/images/cards/tarot';
  static const String tarotMajor = '$tarotRoot/major';
  static const String tarotCups = '$tarotRoot/cups';
  static const String tarotWands = '$tarotRoot/wands';
  static const String tarotSwords = '$tarotRoot/swords';
  static const String tarotPentacles = '$tarotRoot/pentacles';
}
