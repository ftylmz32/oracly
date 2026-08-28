/// Parse structured OR context from proxy JSON — kinds stay isolated.
library;

import '../contexts/reading_ai_context.dart';

abstract final class ReadingContextFromJson {
  ReadingContextFromJson._();

  static ReadingAiContext? parse(Map<String, dynamic> json) {
    return switch ((json['kind'] as String?)?.trim()) {
      'tarot' => _tarot(json),
      'dream' => _dream(json),
      'astrology' => _astrology(json),
      'birthChart' => _birth(json),
      'coffee' => _coffee(json),
      _ => null,
    };
  }

  static TarotAiContext? _tarot(Map<String, dynamic> json) {
    final sessionId = _text(json, 'sessionId');
    final cards = _text(json, 'cardsSummary');
    if (sessionId.isEmpty || cards.isEmpty) return null;
    return TarotAiContext(
      sessionId: sessionId,
      spreadLabel: _text(json, 'spreadLabel'),
      readingTitle: _text(json, 'readingTitle'),
      cardsSummary: cards,
      interpretationSummary: _text(json, 'interpretationSummary'),
      fullInterpretation: _opt(json, 'fullInterpretation'),
      userQuestion: _opt(json, 'userQuestion'),
      cardNames: _strings(json['cardNames']),
    );
  }

  static DreamAiContext? _dream(Map<String, dynamic> json) {
    final narrative = _text(json, 'narrative');
    if (narrative.isEmpty) return null;
    return DreamAiContext(
      narrative: narrative,
      symbols: _strings(json['symbols']),
      emotions: _strings(json['emotions']),
      analysis: _opt(json, 'analysis'),
      emotionalTheme: _opt(json, 'emotionalTheme'),
      fullInterpretation: _opt(json, 'fullInterpretation'),
    );
  }

  static AstrologyAiContext? _astrology(Map<String, dynamic> json) {
    final sign = _text(json, 'signLabel');
    final daily = _text(json, 'daily');
    if (sign.isEmpty || daily.isEmpty) return null;
    return AstrologyAiContext(
      signLabel: sign,
      daily: daily,
      readingType: _text(json, 'readingType', fallback: 'Günlük'),
      personality: _opt(json, 'personality'),
      love: _opt(json, 'love'),
      career: _opt(json, 'career'),
      money: _opt(json, 'money'),
      energy: _opt(json, 'energy'),
      emotion: _opt(json, 'emotion'),
      advice: _opt(json, 'advice'),
      fullInterpretation: _opt(json, 'fullInterpretation'),
    );
  }

  static BirthChartAiContext? _birth(Map<String, dynamic> json) {
    final sun = _text(json, 'sunLabel');
    final interpretation = _text(json, 'interpretation');
    if (sun.isEmpty || interpretation.isEmpty) return null;
    return BirthChartAiContext(
      sunLabel: sun,
      interpretation: interpretation,
      summary: _opt(json, 'summary'),
      strongThemes: _opt(json, 'strongThemes'),
      notableThemes: _opt(json, 'notableThemes'),
      placements: _strings(json['placements']),
      birthLine: _opt(json, 'birthLine'),
      fullInterpretation: _opt(json, 'fullInterpretation'),
    );
  }

  static CoffeeAiContext? _coffee(Map<String, dynamic> json) {
    final overall = _text(json, 'overall');
    if (overall.isEmpty) return null;
    return CoffeeAiContext(
      overall: overall,
      visualObservation: _opt(json, 'visualObservation'),
      love: _opt(json, 'love'),
      career: _opt(json, 'career'),
      money: _opt(json, 'money'),
      nearFuture: _opt(json, 'nearFuture'),
      takeaway: _opt(json, 'takeaway'),
      symbolNames: _strings(json['symbolNames']),
      fullInterpretation: _opt(json, 'fullInterpretation'),
    );
  }

  static String _text(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static String? _opt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
