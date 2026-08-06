/// OR-050 — Daily energy reading model.
library;

import 'package:flutter/material.dart';

/// Full daily energy payload shown on the details screen.
@immutable
class DailyEnergyReading {
  const DailyEnergyReading({
    required this.summary,
    required this.love,
    required this.career,
    required this.money,
    required this.mood,
    required this.luckyNumber,
    required this.luckyColor,
    required this.luckyColorHex,
    required this.luckyCrystal,
    required this.cosmicMessage,
    required this.aiInterpretation,
    required this.moonPhaseLabel,
    required this.dateLabel,
  });

  final String summary;
  final String love;
  final String career;
  final String money;
  final String mood;
  final int luckyNumber;
  final String luckyColor;
  final Color luckyColorHex;
  final String luckyCrystal;
  final String cosmicMessage;
  final String aiInterpretation;
  final String moonPhaseLabel;
  final String dateLabel;
}

/// Insight category for the four glass tiles.
enum DailyEnergyInsight {
  love(Icons.favorite_rounded, 'Aşk'),
  career(Icons.work_rounded, 'Kariyer'),
  money(Icons.payments_rounded, 'Para'),
  mood(Icons.self_improvement_rounded, 'Ruh Hali');

  const DailyEnergyInsight(this.icon, this.label);

  final IconData icon;
  final String label;
}
