/// Canonical deck enums — one structure for all 78 cards.
library;

enum OraclyTarotArcana { major, minor }

enum OraclyTarotSuit { none, wands, cups, swords, pentacles }

abstract final class OraclyTarotRanks {
  OraclyTarotRanks._();

  static const ace = 1;
  static const page = 11;
  static const knight = 12;
  static const queen = 13;
  static const king = 14;
}
