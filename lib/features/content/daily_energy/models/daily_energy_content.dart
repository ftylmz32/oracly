/// OR-1150 — Daily energy content models.
library;

import '../../shared/services/content_search_service.dart';

class LuckyColor {
  const LuckyColor({
    required this.name,
    required this.hex,
    required this.meaning,
  });

  final String name;
  final String hex;
  final String meaning;

  Map<String, dynamic> toJson() => {
        'name': name,
        'hex': hex,
        'meaning': meaning,
      };
}

class LuckyNumber {
  const LuckyNumber({
    required this.value,
    required this.meaning,
  });

  final int value;
  final String meaning;

  Map<String, dynamic> toJson() => {
        'value': value,
        'meaning': meaning,
      };
}

class LuckyCrystal {
  const LuckyCrystal({
    required this.name,
    required this.chakra,
    required this.intention,
  });

  final String name;
  final String chakra;
  final String intention;

  Map<String, dynamic> toJson() => {
        'name': name,
        'chakra': chakra,
        'intention': intention,
      };
}

class SpiritMessage {
  const SpiritMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.theme,
  });

  final String id;
  final String title;
  final String message;
  final String theme;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'theme': theme,
      };
}

class MoonInfluence {
  const MoonInfluence({
    required this.phase,
    required this.label,
    required this.influence,
    required this.ritualHint,
  });

  final String phase;
  final String label;
  final String influence;
  final String ritualHint;

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'label': label,
        'influence': influence,
        'ritualHint': ritualHint,
      };
}

class ElementEnergy {
  const ElementEnergy({
    required this.element,
    required this.quality,
    required this.guidance,
  });

  final String element;
  final String quality;
  final String guidance;

  Map<String, dynamic> toJson() => {
        'element': element,
        'quality': quality,
        'guidance': guidance,
      };
}

class DailyEnergyContent implements SearchableContent {
  const DailyEnergyContent({
    required this.id,
    required this.date,
    required this.summary,
    required this.vibrationScore,
    required this.luckyColor,
    required this.luckyNumber,
    required this.luckyCrystal,
    required this.spiritMessage,
    required this.moonInfluence,
    required this.elementEnergy,
    required this.weekTheme,
    required this.loveHint,
    required this.careerHint,
    required this.moneyHint,
    required this.moodHint,
  });

  final String id;
  final DateTime date;
  final String summary;
  final double vibrationScore;
  final LuckyColor luckyColor;
  final LuckyNumber luckyNumber;
  final LuckyCrystal luckyCrystal;
  final SpiritMessage spiritMessage;
  final MoonInfluence moonInfluence;
  final ElementEnergy elementEnergy;
  final String weekTheme;
  final String loveHint;
  final String careerHint;
  final String moneyHint;
  final String moodHint;

  @override
  String get contentId => id;

  @override
  String get displayName => 'Günlük Enerji ${date.day}.${date.month}';

  @override
  String get searchText =>
      '$summary ${luckyColor.name} ${luckyCrystal.name} ${spiritMessage.title}';

  @override
  List<String> get categories => [
        elementEnergy.element,
        moonInfluence.phase,
        weekTheme,
      ];

  @override
  List<String> get tags => [
        luckyColor.name,
        luckyCrystal.name,
        spiritMessage.theme,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'summary': summary,
        'vibrationScore': vibrationScore,
        'luckyColor': luckyColor.toJson(),
        'luckyNumber': luckyNumber.toJson(),
        'luckyCrystal': luckyCrystal.toJson(),
        'spiritMessage': spiritMessage.toJson(),
        'moonInfluence': moonInfluence.toJson(),
        'elementEnergy': elementEnergy.toJson(),
        'weekTheme': weekTheme,
        'loveHint': loveHint,
        'careerHint': careerHint,
        'moneyHint': moneyHint,
        'moodHint': moodHint,
      };
}
