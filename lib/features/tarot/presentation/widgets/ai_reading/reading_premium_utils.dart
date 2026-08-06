/// OR-301 — Display helpers for premium reading UI (no business logic).
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/session_ending_copy.dart';
import '../../../models/tarot_card.dart';
import 'ai_reading_content.dart';

abstract final class ReadingPremiumUtils {
  ReadingPremiumUtils._();

  static String condense(String text, {int maxChars = 160}) {
    final trimmed = text.trim();
    if (trimmed.length <= maxChars) return trimmed;
    final cut = trimmed.substring(0, maxChars);
    final lastSpace = cut.lastIndexOf(' ');
    if (lastSpace > maxChars * 0.6) {
      return '${cut.substring(0, lastSpace)}…';
    }
    return '$cut…';
  }

  static String affirmationFrom(AiReadingContent content) {
    return SessionEndingCopy.affirmationBeat(content);
  }

  static TarotCard? primaryCard(AiReadingContent content) {
    if (content.drawnCards.isEmpty) return null;
    return content.drawnCards.first.card;
  }

  static String elementLabel(TarotCard? card) {
    if (card?.element != null && card!.element!.isNotEmpty) {
      return _trElement(card.element!);
    }
    return 'Evrensel';
  }

  static String arcanaLabel(TarotCard? card) {
    if (card == null) return 'Arcana';
    return card.isMajor ? 'Major Arcana' : 'Minor Arcana';
  }

  static String rarityLabel(TarotCard? card, Color rarityColor) {
    if (card == null) return 'Kutsal';
    if (card.isMajor) return 'Efsanevi';
    return 'Nadir';
  }

  static ({double love, double career, double spiritual}) energyValues(
    AiReadingContent content,
  ) {
    final card = primaryCard(content);
    if (card != null &&
        (card.energyEffect + card.intuitionEffect + card.luckEffect) > 0) {
      return (
        love: _norm(card.intuitionEffect),
        career: _norm(card.energyEffect),
        spiritual: _norm(card.luckEffect),
      );
    }
    return (
      love: _norm(content.love.length * 3 + 40),
      career: _norm(content.career.length * 3 + 35),
      spiritual: _norm(content.spiritualGuidance.length * 3 + 45),
    );
  }

  static double _norm(int raw) => (raw / 100).clamp(0.52, 0.96);

  static UniversalFrequencyData universalFrequency(AiReadingContent content) {
    final card = primaryCard(content);
    final now = DateTime.now();
    final phase = _moonPhase(now);
    final intuition = (energyValues(content).spiritual * 100).round();
    final luckyNum = (card?.id ?? 7) % 9 + 1;
    final luckyHour = '${(19 + luckyNum % 4).toString().padLeft(2, '0')}:30';

    return UniversalFrequencyData(
      frequencyHz: 528,
      intuitionPercent: intuition.clamp(72, 98),
      moonPhase: _moonPhaseLabel(phase),
      luckyHour: luckyHour,
      luckyNumber: luckyNum,
    );
  }

  static double _moonPhase(DateTime date) {
    var y = date.year;
    var m = date.month;
    if (m < 3) {
      y--;
      m += 12;
    }
    final c = 365.25 * y + 30.6 * (m + 1) + date.day - 694039.09;
    return (c / 29.5305882) - (c / 29.5305882).floorToDouble();
  }

  static String _moonPhaseLabel(double phase) {
    if (phase < 0.06 || phase > 0.94) return 'New Moon';
    if (phase < 0.22) return 'Waxing Crescent';
    if (phase < 0.28) return 'First Quarter';
    if (phase < 0.44) return 'Waxing Gibbous';
    if (phase < 0.56) return 'Full Moon';
    if (phase < 0.72) return 'Waning Gibbous';
    if (phase < 0.78) return 'Last Quarter';
    return 'Waning Crescent';
  }

  static String _trElement(String e) {
    return switch (e.toLowerCase()) {
      'fire' || 'ateş' => 'Ateş',
      'water' || 'su' => 'Su',
      'air' || 'hava' => 'Hava',
      'earth' || 'toprak' => 'Toprak',
      _ => e,
    };
  }
}

@immutable
class UniversalFrequencyData {
  const UniversalFrequencyData({
    required this.frequencyHz,
    required this.intuitionPercent,
    required this.moonPhase,
    required this.luckyHour,
    required this.luckyNumber,
  });

  final int frequencyHz;
  final int intuitionPercent;
  final String moonPhase;
  final String luckyHour;
  final int luckyNumber;
}
