/// Scores robotic repetition — never bans a word on first use.
library;

import '../copy/fortune_voice.dart';
import 'human_reader_guard.dart';

class RoboticLanguageReport {
  const RoboticLanguageReport({required this.score, required this.signals});

  final double score;
  final List<String> signals;

  bool get isHeavilyRepetitive => score >= 4;
  bool get needsRewrite => score >= 2;
}

abstract final class RoboticLanguageDetector {
  RoboticLanguageDetector._();

  static const _softCounts = <String, int>{
    'enerji': 3,
    'farkındalık': 2,
    'senin için': 3,
    'tema': 3,
    'yansıma': 3,
    'yansım': 3,
    'ön plana': 2,
    'öne çık': 2,
    'dikkat çek': 2,
    'hareketlilik': 2,
  };

  static const _emptyPositivity = [
    'her şey yoluna',
    'güzel günler',
    'pozitif enerji',
    'harika bir dönem',
    'everything will be fine',
    'stay positive',
  ];

  static RoboticLanguageReport analyze(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const RoboticLanguageReport(score: 0, signals: []);
    }
    final lower = trimmed.toLowerCase();
    final signals = <String>[];
    var score = 0.0;

    if (RegExp(r'^#{1,3}\s', multiLine: true).hasMatch(trimmed)) {
      score += 2;
      signals.add('markdown_heading');
    }
    if (RegExp(
      r'^(ANA HİS|SEMBOLİK YORUM|DİKKAT ÇEKEN|KİŞİSEL BAĞLAM|GENEL YORUM)\b',
      multiLine: true,
      caseSensitive: false,
    ).hasMatch(trimmed)) {
      score += 2;
      signals.add('section_label');
    }

    for (final entry in _softCounts.entries) {
      final count = _count(lower, entry.key);
      if (count >= entry.value) {
        score += (count - entry.value + 1) * 1.5;
        signals.add('${entry.key}×$count');
      }
    }

    if (_emptyPositivity.any(lower.contains)) {
      score += 2;
      signals.add('empty_positivity');
    }

    final roboticHits =
        FortuneVoice.robotic.where((p) => lower.contains(p)).length;
    if (roboticHits >= 2) {
      score += roboticHits * 1.5;
      signals.add('stock_phrase×$roboticHits');
    } else if (roboticHits == 1 && trimmed.length < 180) {
      score += 1.5;
      signals.add('stock_phrase');
    }

    final openers = _openerCount(trimmed);
    if (openers >= 2) {
      score += (openers - 1) * 2;
      signals.add('repeated_opener×$openers');
    }

    final parallel = _parallelStarts(trimmed);
    if (parallel >= 3) {
      score += 2;
      signals.add('parallel_structure×$parallel');
    }

    if (HumanReaderGuard.bureaucratic.where(lower.contains).length >= 2) {
      score += 2;
      signals.add('bureaucratic');
    }

    return RoboticLanguageReport(score: score, signals: signals);
  }

  static bool isHeavilyRepetitive(String text) =>
      analyze(text).isHeavilyRepetitive;

  static int _count(String lower, String phrase) {
    var at = 0;
    var hits = 0;
    while (true) {
      final i = lower.indexOf(phrase, at);
      if (i < 0) break;
      hits++;
      at = i + phrase.length;
    }
    return hits;
  }

  static int _openerCount(String text) {
    final re = RegExp(r'(^|[.!?]\s+)(bu (kart|rüya)\b)', caseSensitive: false);
    return re.allMatches(text).length;
  }

  static int _parallelStarts(String text) {
    final starts = <String, int>{};
    for (final raw in text.split(RegExp(r'(?<=[.!?])\s+'))) {
      final words = raw
          .trim()
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .take(4)
          .join(' ');
      if (words.length < 8) continue;
      starts[words] = (starts[words] ?? 0) + 1;
    }
    if (starts.isEmpty) return 0;
    return starts.values.reduce((a, b) => a > b ? a : b);
  }
}
