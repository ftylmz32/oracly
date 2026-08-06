/// OR-1150 — Complete tarot card content model.
library;

import '../../shared/models/content_types.dart';
import '../../shared/services/content_search_service.dart';

enum TarotContentArcana { major, minor }

enum TarotContentSuit { none, cups, pentacles, swords, wands }

class TarotCardContent implements SearchableContent {
  const TarotCardContent({
    required this.id,
    required this.name,
    required this.nameTr,
    required this.arcana,
    required this.suit,
    required this.number,
    required this.element,
    required this.planet,
    required this.zodiac,
    required this.keywords,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.loveMeaning,
    required this.careerMeaning,
    required this.moneyMeaning,
    required this.healthMeaning,
    required this.spiritualMeaning,
    required this.advice,
    required this.shadowMeaning,
    required this.symbols,
    required this.affirmation,
    required this.imageAsset,
    required this.rarity,
  });

  final int id;
  final String name;
  final String nameTr;
  final TarotContentArcana arcana;
  final TarotContentSuit suit;
  final int number;
  final String element;
  final String planet;
  final String zodiac;
  final List<String> keywords;
  final String uprightMeaning;
  final String reversedMeaning;
  final String loveMeaning;
  final String careerMeaning;
  final String moneyMeaning;
  final String healthMeaning;
  final String spiritualMeaning;
  final String advice;
  final String shadowMeaning;
  final List<String> symbols;
  final String affirmation;
  final String imageAsset;
  final ContentRarity rarity;

  bool get isMajor => arcana == TarotContentArcana.major;

  @override
  String get contentId => 'tarot_$id';

  @override
  String get displayName => nameTr;

  @override
  String get searchText =>
      '$name $nameTr ${keywords.join(' ')} $element $planet $zodiac';

  @override
  List<String> get categories => [
        arcana.name,
        if (suit != TarotContentSuit.none) suit.name,
        element,
      ];

  @override
  List<String> get tags => keywords;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameTr': nameTr,
        'arcana': arcana.name,
        'suit': suit.name,
        'number': number,
        'element': element,
        'planet': planet,
        'zodiac': zodiac,
        'keywords': keywords,
        'uprightMeaning': uprightMeaning,
        'reversedMeaning': reversedMeaning,
        'loveMeaning': loveMeaning,
        'careerMeaning': careerMeaning,
        'moneyMeaning': moneyMeaning,
        'healthMeaning': healthMeaning,
        'spiritualMeaning': spiritualMeaning,
        'advice': advice,
        'shadowMeaning': shadowMeaning,
        'symbols': symbols,
        'affirmation': affirmation,
        'imageAsset': imageAsset,
        'rarity': rarity.name,
      };

  factory TarotCardContent.fromJson(Map<String, dynamic> json) {
    return TarotCardContent(
      id: json['id'] as int,
      name: json['name'] as String,
      nameTr: json['nameTr'] as String,
      arcana: TarotContentArcana.values.byName(json['arcana'] as String),
      suit: TarotContentSuit.values.byName(json['suit'] as String),
      number: json['number'] as int,
      element: json['element'] as String,
      planet: json['planet'] as String,
      zodiac: json['zodiac'] as String,
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
      uprightMeaning: json['uprightMeaning'] as String,
      reversedMeaning: json['reversedMeaning'] as String,
      loveMeaning: json['loveMeaning'] as String,
      careerMeaning: json['careerMeaning'] as String,
      moneyMeaning: json['moneyMeaning'] as String,
      healthMeaning: json['healthMeaning'] as String,
      spiritualMeaning: json['spiritualMeaning'] as String,
      advice: json['advice'] as String,
      shadowMeaning: json['shadowMeaning'] as String,
      symbols: (json['symbols'] as List<dynamic>).cast<String>(),
      affirmation: json['affirmation'] as String,
      imageAsset: json['imageAsset'] as String,
      rarity: ContentRarity.values.byName(json['rarity'] as String),
    );
  }
}
