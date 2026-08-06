/// OR-1100 — Tarot card domain model.
library;

enum TarotArcanaType { major, minor }

enum TarotSuitType { none, cups, pentacles, swords, wands }

class TarotCardModel {
  const TarotCardModel({
    required this.id,
    required this.name,
    required this.nameTr,
    required this.imageAsset,
    required this.arcana,
    required this.suit,
    required this.number,
    required this.keywords,
    required this.summary,
    this.element,
    this.planet,
    this.zodiac,
  });

  final int id;
  final String name;
  final String nameTr;
  final String imageAsset;
  final TarotArcanaType arcana;
  final TarotSuitType suit;
  final int number;
  final List<String> keywords;
  final String summary;
  final String? element;
  final String? planet;
  final String? zodiac;

  bool get isMajor => arcana == TarotArcanaType.major;
}
