/// OR-1080 — Card detail encyclopedia models.
library;

import 'package:flutter/material.dart';

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

  static const sectionTitles = <(String key, String title, IconData icon)>[
    ('general', 'Genel Anlam', Icons.auto_stories_rounded),
    ('upright', 'Düz Anlam', Icons.arrow_upward_rounded),
    ('reversed', 'Ters Anlam', Icons.arrow_downward_rounded),
    ('love', 'Aşk', Icons.favorite_rounded),
    ('career', 'Kariyer', Icons.work_outline_rounded),
    ('money', 'Para', Icons.payments_outlined),
    ('spiritual', 'Ruhsal Anlam', Icons.self_improvement_rounded),
    ('health', 'Sağlık', Icons.healing_rounded),
    ('personality', 'Kişilik', Icons.person_outline_rounded),
    ('shadow', 'Gölge Yön', Icons.dark_mode_outlined),
    ('advice', 'Tavsiye', Icons.lightbulb_outline_rounded),
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
