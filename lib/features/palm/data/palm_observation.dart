/// Vision facts only. Never adds length, breaks, branches, or medical claims.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../models/palm_reading.dart';

abstract final class PalmObservation {
  PalmObservation._();

  /// Explicit visibility phrases: the line itself could not be read.
  static const absent = [
    'görünmüyor',
    'görünmez',
    'görülemiyor',
    'seçilemiyor',
    'not visible',
    'не видн',
    'too faint',
  ];

  /// "yok" marks the line absent only when the line is its subject
  /// ("Kalp çizgisi yok."); "kopukluk yok" denies a property instead.
  static final _lineAbsent = RegExp(
    r'(?<![\p{L}\p{M}\p{N}])çizgi(?:si|ler|leri)?\s+'
    r'(?:(?:burada|avuçta|elde)\s+)?yok(?![\p{L}\p{M}\p{N}])',
    unicode: true,
  );
  static final _clauseBreak = RegExp(r'[.!?;:,\n]');

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

  static bool missing(String text) {
    if (text.trim().isEmpty) return true;
    if (absent.any((term) => hasTerm(text, term))) return true;
    final folded = _fold(text);
    if (_lineAbsent.hasMatch(folded)) return true;
    return folded.split(_clauseBreak).any((clause) => clause.trim() == 'yok');
  }

  static List<String> marks(Iterable<String> names) => [
        for (final name in names)
          if (name.trim().isNotEmpty) name.trim(),
      ];

  /// True when [term] starts at a token boundary in [text]; Turkish
  /// suffixes may follow ("ölümü"). Unicode-aware, unlike ASCII `\b`.
  static bool hasTerm(String text, String term) {
    final pattern = _patterns.putIfAbsent(
      term,
      () => RegExp(
        '(?<![\\p{L}\\p{M}\\p{N}])${RegExp.escape(term)}',
        unicode: true,
      ),
    );
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
