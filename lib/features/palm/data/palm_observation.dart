/// Vision facts only. Never adds length, breaks, branches, or medical claims.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../models/palm_reading.dart';

abstract final class PalmObservation {
  PalmObservation._();

  static const absent = [
    'görünmüyor',
    'görünmez',
    'görülemiyor',
    'seçilemiyor',
    'yok',
    'not visible',
    'не видн',
    'too faint',
  ];

  /// Terms that must also end at a token boundary ("yok" ≠ "yokluğundan").
  /// Every other term may carry Turkish suffixes ("ölümü", "hastalığı").
  static const wholeWord = {'yok'};

  static const textbook = [
    'temsil eder',
    'represents',
    'означает',
    'demektir',
    'şu anlama gelir',
    'means that',
    'uzun ömür',
    'lifespan',
    'yaşam süresi',
    'dallanma',
    'forked line',
    'break in the',
    'hastalık',
    'hastalığ',
    'ölüm',
    'death',
    'ömrün',
    'teşhis',
    'diagnosis',
    'prognosis',
  ];

  /// Openers that only make sense after the preceding sentence.
  static const _anaphora = {
    'bu', 'bunun', 'bunu', 'buna', 'bundan', 'bunlar', 'böylece', //
    'this', 'these', 'that', //
    'это', 'этот', 'эта', 'эти',
  };

  static final _tokenChar = RegExp(r'[\p{L}\p{M}\p{N}]', unicode: true);
  static final _patterns = <String, RegExp>{};

  static String ground(String raw) {
    final scrubbed = HumanReader.guard(FortuneVoice.scrub(raw));
    if (scrubbed.isEmpty) return '';
    final kept = <String>[];
    var antecedentLost = false;
    for (final part in scrubbed.split(RegExp(r'(?<=[.!?])\s+'))) {
      final text = part.trim();
      if (text.isEmpty) continue;
      if (_drop(text) || (antecedentLost && _dependsOnPrevious(text))) {
        antecedentLost = true;
        continue;
      }
      antecedentLost = false;
      kept.add(text);
    }
    return kept.join(' ').trim();
  }

  static String shapeOf(PalmReading raw) {
    final overall = ground(raw.overall);
    if (overall.isEmpty) return '';
    final first = overall.split(RegExp(r'(?<=[.!?])\s+')).first.trim();
    return _bare(first);
  }

  static String line(String observed) {
    final text = ground(observed);
    if (text.isEmpty || missing(text)) return '';
    return text;
  }

  static bool missing(String text) =>
      text.trim().isEmpty || absent.any((term) => hasTerm(text, term));

  static List<String> marks(Iterable<String> names) => [
        for (final name in names)
          if (name.trim().isNotEmpty) name.trim(),
      ];

  /// True when [term] starts at a token boundary in [text]; [wholeWord]
  /// terms must end at one too. Unicode-aware, unlike ASCII `\b`.
  static bool hasTerm(String text, String term) {
    final pattern = _patterns.putIfAbsent(term, () {
      final tail = wholeWord.contains(term) ? r'(?![\p{L}\p{M}\p{N}])' : '';
      return RegExp(
        '(?<![\\p{L}\\p{M}\\p{N}])${RegExp.escape(term)}$tail',
        unicode: true,
      );
    });
    return pattern.hasMatch(_fold(text));
  }

  static bool _drop(String text) {
    if (text.contains('=')) return true;
    if (textbook.any((term) => hasTerm(text, term))) return true;
    if (FortuneVoice.claimsMedical(text)) return true;
    if (FortuneVoice.claimsCertainty(text)) return true;
    return FortuneVoice.looksRobotic(text);
  }

  static bool _dependsOnPrevious(String text) {
    final folded = _fold(text);
    var end = 0;
    while (end < folded.length && _tokenChar.hasMatch(folded[end])) {
      end++;
    }
    return _anaphora.contains(folded.substring(0, end));
  }

  /// Lowercase; folds the dotted "İ" → "i̇" artefact back to plain "i".
  static String _fold(String text) =>
      text.toLowerCase().replaceAll('i\u0307', 'i');

  static String _bare(String text) {
    if (text.isEmpty) return text;
    final last = text[text.length - 1];
    if (last == '.' || last == '!' || last == '?') {
      return text.substring(0, text.length - 1).trim();
    }
    return text;
  }
}
