/// OR-1140 — Default configurable rule sets per engine.
library;

import '../rules/rule_set.dart';

abstract final class DefaultRuleSets {
  DefaultRuleSets._();

  static RuleSet tarot = RuleSet.fromMap({
    'id': 'tarot_default',
    'engine': 'tarot',
    'version': '1.0.0',
    'rules': [
      {
        'id': 'tarot_spread_layout',
        'when': "spreadType == 'singleCard'",
        'priority': 10,
        'outcome': {
          'sectionKey': 'layout',
          'titleKey': 'tarot.layout.title',
          'contentKey': 'tarot.layout.single',
        },
      },
      {
        'id': 'tarot_spread_three',
        'when': "spreadType == 'threeCards'",
        'priority': 10,
        'outcome': {
          'sectionKey': 'layout',
          'titleKey': 'tarot.layout.title',
          'contentKey': 'tarot.layout.three',
        },
      },
      {
        'id': 'tarot_reversed',
        'when': 'exists reversed',
        'priority': 5,
        'outcome': {
          'sectionKey': 'reversed',
          'titleKey': 'tarot.reversed.title',
          'contentKey': 'tarot.reversed.note',
        },
      },
    ],
  });

  static RuleSet dream = RuleSet.fromMap({
    'id': 'dream_default',
    'engine': 'dream',
    'rules': [
      {
        'id': 'dream_symbols',
        'when': 'symbolCount >= 1',
        'priority': 10,
        'outcome': {
          'sectionKey': 'symbols',
          'titleKey': 'dream.symbols.title',
          'contentKey': 'dream.symbols.summary',
        },
      },
    ],
  });

  static RuleSet astrology = RuleSet.fromMap({
    'id': 'astrology_default',
    'engine': 'astrology',
    'rules': [
      {
        'id': 'astro_sun',
        'when': 'exists sunSign',
        'priority': 10,
        'outcome': {
          'sectionKey': 'sun',
          'titleKey': 'astro.sun.title',
          'contentKey': 'astro.sun.summary',
        },
      },
    ],
  });

  static RuleSet dailyEnergy = RuleSet.fromMap({
    'id': 'energy_default',
    'engine': 'dailyEnergy',
    'rules': [
      {
        'id': 'energy_vibration',
        'when': 'vibrationScore >= 0',
        'priority': 10,
        'outcome': {
          'sectionKey': 'vibration',
          'titleKey': 'energy.vibration.title',
          'contentKey': 'energy.vibration.summary',
        },
      },
    ],
  });

  static RuleSet compatibility = RuleSet.fromMap({
    'id': 'compatibility_default',
    'engine': 'compatibility',
    'rules': [
      {
        'id': 'compat_score',
        'when': 'overallScore >= 0',
        'priority': 10,
        'outcome': {
          'sectionKey': 'score',
          'titleKey': 'compat.score.title',
          'contentKey': 'compat.score.summary',
        },
      },
    ],
  });

  static RuleSet numerology = RuleSet.fromMap({
    'id': 'numerology_default',
    'engine': 'numerology',
    'rules': [
      {
        'id': 'num_life_path',
        'when': 'exists lifePathNumber',
        'priority': 10,
        'outcome': {
          'sectionKey': 'life_path',
          'titleKey': 'num.life_path.title',
          'contentKey': 'num.life_path.summary',
        },
      },
    ],
  });

  static List<RuleSet> get all => [
        tarot,
        dream,
        astrology,
        dailyEnergy,
        compatibility,
        numerology,
      ];
}
