/// Structured daily astrology reading — answer-first, sign-aware.
library;

import 'package:flutter/foundation.dart';

@immutable
class AstrologyDailyReading {
  const AstrologyDailyReading({
    required this.personality,
    required this.overall,
    required this.love,
    required this.career,
    required this.money,
    required this.advice,
    required this.energy,
    required this.emotion,
    required this.opportunity,
    required this.caution,
    this.innerTheme = '',
  });

  final String personality;
  final String overall;
  final String love;
  final String career;
  final String money;
  final String advice;
  final String energy;
  final String emotion;
  final String opportunity;
  final String caution;
  final String innerTheme;

  String get loveBrief => firstSentence(love);
  String get careerBrief => firstSentence(career);
  String get moneyBrief => firstSentence(money);
  String get adviceBrief => firstSentence(advice);
  String get energyBrief => firstSentence(energy);

  static String firstSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final dot = trimmed.indexOf('.');
    if (dot > 0 && dot < trimmed.length - 1) {
      return trimmed.substring(0, dot + 1);
    }
    return trimmed.endsWith('.') ? trimmed : '$trimmed.';
  }

  AstrologyDailyReading copyWith({
    String? overall,
    String? love,
    String? career,
    String? money,
    String? advice,
    String? energy,
    String? emotion,
    String? opportunity,
    String? caution,
    String? innerTheme,
  }) {
    return AstrologyDailyReading(
      personality: personality,
      overall: overall ?? this.overall,
      love: love ?? this.love,
      career: career ?? this.career,
      money: money ?? this.money,
      advice: advice ?? this.advice,
      energy: energy ?? this.energy,
      emotion: emotion ?? this.emotion,
      opportunity: opportunity ?? this.opportunity,
      caution: caution ?? this.caution,
      innerTheme: innerTheme ?? this.innerTheme,
    );
  }
}
