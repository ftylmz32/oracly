/// Structured Yıldızname readings — answer-first, not question-only.
library;

import 'package:flutter/foundation.dart';

import '../../../core/l10n/l10n.dart';

enum StarMapPolarity { supportive, challenging, balanced }

@immutable
class StarMapPlanetInfluence {
  const StarMapPlanetInfluence({
    required this.nameTr,
    required this.influence,
    required this.explanation,
    required this.polarity,
  });

  final String nameTr;
  final String influence;
  final String explanation;
  final StarMapPolarity polarity;

  String get polarityLabel => switch (polarity) {
        StarMapPolarity.supportive => OraclyL10n.t('star.polarity.supportive'),
        StarMapPolarity.challenging => OraclyL10n.t('star.polarity.challenging'),
        StarMapPolarity.balanced => OraclyL10n.t('star.polarity.balanced'),
      };
}

@immutable
class StarMapOverview {
  const StarMapOverview({
    required this.whatItSays,
    required this.dominantEnergy,
    required this.mainMessage,
  });

  final String whatItSays;
  final String dominantEnergy;
  final String mainMessage;
}

@immutable
class StarMapSkyMessage {
  const StarMapSkyMessage({
    required this.today,
    required this.interpretation,
    required this.advice,
  });

  final String today;
  final String interpretation;
  final String advice;
}

@immutable
class StarMapKarmicReading {
  const StarMapKarmicReading({
    required this.theme,
    required this.learning,
    required this.interpretation,
    required this.takeaway,
    this.promptQuestion = '',
  });

  final String theme;
  final String learning;
  final String interpretation;
  final String takeaway;
  final String promptQuestion;
}

@immutable
class StarMapReading {
  const StarMapReading({
    required this.overview,
    required this.skyMessage,
    required this.karmic,
    required this.planets,
    this.isPersonalized = false,
    this.sunLabel,
    this.innerThemesLine = '',
    this.recurringThemesLine = '',
    this.todayReflection = '',
  });

  final StarMapOverview overview;
  final StarMapSkyMessage skyMessage;
  final StarMapKarmicReading karmic;
  final List<StarMapPlanetInfluence> planets;
  final bool isPersonalized;
  final String? sunLabel;

  /// Real Personal Discovery themes only — never catalogue karmic copy.
  final String innerThemesLine;
  final String recurringThemesLine;
  final String todayReflection;
}
