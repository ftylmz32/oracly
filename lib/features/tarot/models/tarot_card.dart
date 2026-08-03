enum TarotArcana {
  major,
  minor,
}

enum TarotSuit {
  none,
  cups,
  pentacles,
  swords,
  wands,
}

enum TarotRank {
  none,
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  page,
  knight,
  queen,
  king,
}

class TarotCard {
  final int id;
  final String name;
  final String image;
  final TarotArcana arcana;
  final TarotSuit suit;
  final TarotRank rank;
  final int number;
  final String summary;
  final String meaning;
  final String reversedMeaning;
  final List<String> keywords;
  final String? element;
  final String? planet;
  final String? zodiac;
  final int? numerology;
  final int energyEffect;
  final int intuitionEffect;
  final int luckEffect;

  const TarotCard({
    required this.id,
    required this.name,
    required this.image,
    required this.arcana,
    required this.suit,
    this.rank = TarotRank.none,
    required this.number,
    required this.summary,
    required this.meaning,
    required this.reversedMeaning,
    required this.keywords,
    this.element,
    this.planet,
    this.zodiac,
    this.numerology,
    this.energyEffect = 0,
    this.intuitionEffect = 0,
    this.luckEffect = 0,
  });

  bool get isMajor => arcana == TarotArcana.major;

  bool get isMinor => arcana == TarotArcana.minor;
}
