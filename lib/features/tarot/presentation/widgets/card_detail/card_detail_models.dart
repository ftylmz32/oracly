/// OR-1080 — Card detail encyclopedia models.
library;

import 'package:flutter/material.dart';

import 'package:oracly_new/core/l10n/l10n.dart';

/// One symbolic element illustrated on the card art.
class CardSymbolEntry {
  const CardSymbolEntry({
    required this.name,
    required this.icon,
    required this.description,
  });

  final String name;
  final IconData icon;
  final String description;
}

/// All expandable meaning sections for one card.
class CardMeaningSections {
  const CardMeaningSections({
    required this.general,
    required this.upright,
    required this.reversed,
    required this.love,
    required this.career,
    required this.money,
    required this.spiritual,
    required this.health,
    required this.personality,
    required this.shadow,
    required this.advice,
  });

  final String general;
  final String upright;
  final String reversed;
  final String love;
  final String career;
  final String money;
  final String spiritual;
  final String health;
  final String personality;
  final String shadow;
  final String advice;

  static List<(String key, String title, IconData icon)> get sectionTitles => [
        ('general', OraclyL10n.t('tarot.section.general'), Icons.auto_stories_rounded),
        ('upright', OraclyL10n.t('tarot.section.upright'), Icons.arrow_upward_rounded),
        ('reversed', OraclyL10n.t('tarot.section.reversed'), Icons.arrow_downward_rounded),
        ('love', OraclyL10n.t('tarot.section.love'), Icons.favorite_rounded),
        ('career', OraclyL10n.t('tarot.section.career'), Icons.work_outline_rounded),
        ('money', OraclyL10n.t('tarot.section.money'), Icons.payments_outlined),
        ('spiritual', OraclyL10n.t('tarot.section.spiritual'), Icons.self_improvement_rounded),
        ('health', OraclyL10n.t('tarot.section.health'), Icons.healing_rounded),
        ('personality', OraclyL10n.t('tarot.section.personality'), Icons.person_outline_rounded),
        ('shadow', OraclyL10n.t('tarot.section.shadow'), Icons.dark_mode_outlined),
        ('advice', OraclyL10n.t('tarot.section.advice'), Icons.lightbulb_outline_rounded),
      ];

  String textForKey(String key) => switch (key) {
        'general' => general,
        'upright' => upright,
        'reversed' => reversed,
        'love' => love,
        'career' => career,
        'money' => money,
        'spiritual' => spiritual,
        'health' => health,
        'personality' => personality,
        'shadow' => shadow,
        'advice' => advice,
        _ => general,
      };
}

/// Full encyclopedia entry for one tarot card.
class CardDetailContent {
  const CardDetailContent({
    required this.id,
    required this.name,
    required this.displayNameTr,
    required this.imageAsset,
    required this.arcanaType,
    required this.element,
    required this.planet,
    required this.zodiac,
    required this.number,
    required this.keywords,
    required this.accentColor,
    required this.meanings,
    required this.symbols,
    required this.aiInsight,
    required this.relatedIds,
    required this.heroTag,
  });

  final int id;
  final String name;
  final String displayNameTr;
  String get displayName => OraclyL10n.t('tarot.card.$id');
  final String imageAsset;
  final String arcanaType;
  final String element;
  final String planet;
  final String zodiac;
  final int number;
  final List<String> keywords;
  final Color accentColor;
  final CardMeaningSections meanings;
  final List<CardSymbolEntry> symbols;
  final String aiInsight;
  final List<int> relatedIds;
  final String heroTag;
}
