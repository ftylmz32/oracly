/// OR-1150 — Astrology content models.
library;

import '../../shared/services/content_search_service.dart';

enum ZodiacElement { fire, earth, air, water }

enum ZodiacModality { cardinal, fixed, mutable }

class ZodiacSignContent implements SearchableContent {
  const ZodiacSignContent({
    required this.id,
    required this.name,
    required this.nameTr,
    required this.symbol,
    required this.element,
    required this.modality,
    required this.rulingPlanet,
    required this.dateRange,
    required this.traits,
    required this.strengths,
    required this.weaknesses,
    required this.loveStyle,
    required this.careerStyle,
  });

  final String id;
  final String name;
  final String nameTr;
  final String symbol;
  final ZodiacElement element;
  final ZodiacModality modality;
  final String rulingPlanet;
  final String dateRange;
  final List<String> traits;
  final List<String> strengths;
  final List<String> weaknesses;
  final String loveStyle;
  final String careerStyle;

  @override
  String get contentId => id;

  @override
  String get displayName => nameTr;

  @override
  String get searchText =>
      '$name $nameTr ${traits.join(' ')} ${element.name} ${modality.name}';

  @override
  List<String> get categories => [element.name, modality.name];

  @override
  List<String> get tags => traits;
}

class PlanetContent implements SearchableContent {
  const PlanetContent({
    required this.id,
    required this.name,
    required this.nameTr,
    required this.domain,
    required this.influence,
    required this.retrogradeNote,
  });

  final String id;
  final String name;
  final String nameTr;
  final String domain;
  final String influence;
  final String retrogradeNote;

  @override
  String get contentId => id;

  @override
  String get displayName => nameTr;

  @override
  String get searchText => '$name $nameTr $domain $influence';

  @override
  List<String> get categories => ['planet'];

  @override
  List<String> get tags => [domain];
}

class HouseContent implements SearchableContent {
  const HouseContent({
    required this.number,
    required this.nameTr,
    required this.theme,
    required this.lifeArea,
  });

  final int number;
  final String nameTr;
  final String theme;
  final String lifeArea;

  @override
  String get contentId => 'house_$number';

  @override
  String get displayName => '$number. Ev — $nameTr';

  @override
  String get searchText => '$nameTr $theme $lifeArea';

  @override
  List<String> get categories => ['house'];

  @override
  List<String> get tags => [theme, lifeArea];
}

class AspectContent {
  const AspectContent({
    required this.name,
    required this.nameTr,
    required this.degrees,
    required this.nature,
    required this.meaning,
  });

  final String name;
  final String nameTr;
  final int degrees;
  final String nature;
  final String meaning;
}

class CompatibilityContent implements SearchableContent {
  const CompatibilityContent({
    required this.id,
    required this.signA,
    required this.signB,
    required this.score,
    required this.summary,
    required this.strengths,
    required this.challenges,
  });

  final String id;
  final String signA;
  final String signB;
  final int score;
  final String summary;
  final List<String> strengths;
  final List<String> challenges;

  @override
  String get contentId => id;

  @override
  String get displayName => '$signA & $signB';

  @override
  String get searchText => '$signA $signB $summary ${strengths.join(' ')}';

  @override
  List<String> get categories => ['compatibility'];

  @override
  List<String> get tags => [signA, signB];
}
