/// Invented biography and novelistic voice. Structures, not a banned noun.
library;

final class YildiznameVoiceLifeReport {
  const YildiznameVoiceLifeReport({
    required this.inventedRoutines,
    required this.literary,
  });

  final int inventedRoutines;
  final bool literary;
}

abstract final class YildiznameVoiceLife {
  YildiznameVoiceLife._();

  static final _same = RegExp(
    r"(?<![0-9A-Za-z_\u00C0-\u024F])aynı(?![0-9A-Za-z_\u00C0-\u024F])",
    caseSensitive: false,
  );
  static final _clockHabit = RegExp(
    r"(?<![0-9A-Za-z_\u00C0-\u024F])(?:her\s+sabah|her\s+gün|her\s+gun|"
    r"sabahları)(?![0-9A-Za-z_\u00C0-\u024F])",
    caseSensitive: false,
  );
  static final _habitVerb = RegExp(
    r"(?:r|z)s[ıiuü]n(?![0-9A-Za-z_\u00C0-\u024F])",
    caseSensitive: false,
  );
  static final _conditional = RegExp(
    r"(?:ince|unca|düğünde|dugunde|dığında|diginda|diğinde)",
    caseSensitive: false,
  );
  static final _scene = RegExp(
    r"seni\b.{0,60}[dt][ıiuü]kların",
    caseSensitive: false,
  );
  static final _sensation = RegExp(
    r"ısın|isin|yumuşa|yumusa",
    caseSensitive: false,
  );
  static final _noticed = RegExp(
    r"fark edilen|göze çarpan|goze carpan",
    caseSensitive: false,
  );
  static final _reversal = RegExp(
    r"^(?:bu|öyle|oyle|duvar|burada)\b",
    caseSensitive: false,
  );

  static YildiznameVoiceLifeReport inspect(
    String summary,
    List<String> sentences,
  ) {
    var routines = 0;
    var reversals = 0;
    var scenes = 0;
    for (final sentence in sentences) {
      if (_invented(sentence)) routines++;
      if (_literarySentence(sentence)) scenes++;
      if (_poeticClose(sentence)) reversals++;
    }
    final opener = sentences.isEmpty ? summary : sentences.first;
    if (_literarySentence(opener)) scenes++;
    return YildiznameVoiceLifeReport(
      inventedRoutines: routines,
      literary: scenes > 0 || reversals >= 3,
    );
  }

  /// "aynı X, aynı Y, aynı Z" as a lived catalogue, or a clocked habit
  /// stated in the aorist. A conditional ("değişince") is not this pattern.
  static bool _invented(String sentence) {
    if (_same.allMatches(sentence).length >= 3) return true;
    return _clockHabit.hasMatch(sentence) &&
        _habitVerb.hasMatch(sentence) &&
        !_conditional.hasMatch(sentence);
  }

  static bool _literarySentence(String sentence) {
    final scene = _scene.hasMatch(sentence);
    final sensation = _sensation.hasMatch(sentence);
    if (scene && sensation) return true;
    return _noticed.hasMatch(sentence) && sensation;
  }

  static bool _poeticClose(String sentence) {
    final words = sentence
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (words > 12) return false;
    return _reversal.hasMatch(sentence.trim()) &&
        RegExp(r'\bdeğil', caseSensitive: false).hasMatch(sentence);
  }
}
