/// OR-1150 — Content asset path constants.
library;

abstract final class ContentAssets {
  ContentAssets._();

  static const String tarotRoot = 'lib/assets/images/cards/tarot';
  static const String tarotMajor = 'lib/assets/images/tarot/major_arcana';
  static const String tarotMinor = 'lib/assets/images/tarot/minor_arcana';
  static const String tarotCups = '$tarotMinor/cups';
  static const String tarotWands = '$tarotMinor/wands';
  static const String tarotSwords = '$tarotMinor/swords';
  static const String tarotPentacles = '$tarotMinor/pentacles';
}
