/// English and Russian word forms for Dream evidence and grounding.
///
/// English: a word and its -s / -es / -ed / -ing forms ("cats", "raining"),
/// never a longer different word ("reduce" is not "red", "season" is not
/// "sea", "catalogue" is not "cat"). Russian: a shared stem of three or more
/// letters with both remainders in the case-ending set ("окно" / "окну").
library;

abstract final class DreamWordForms {
  DreamWordForms._();

  static final _split = RegExp('[^a-z0-9çğöşüâîûа-яё]+');
  static const _enTails = ['ing', 'es', 'ed', 's'];
  static const _ruEndings = {
    '', 'а', 'я', 'о', 'е', 'ы', 'и', 'у', 'ю', 'ь', 'й', 'ой', 'ей', 'ом',
    'ем', 'ам', 'ям', 'ах', 'ях', 'ов', 'ев', 'ью', 'ую', 'юю', 'ая', 'яя',
    'ое', 'ее', 'ые', 'ие', 'ий', 'ый', 'ого', 'его', 'ому', 'ему', 'ым',
    'им', 'ых', 'их', 'ыми', 'ими', 'ами', 'ями',
  };

  static String? _lastText;
  static List<String> _lastWords = const [];

  /// Folded words of [folded], remembered for the last text only — guard
  /// and facts ask about the same told text many times in a row.
  static List<String> words(String folded) {
    if (!identical(folded, _lastText) && folded != _lastText) {
      _lastText = folded;
      _lastWords = folded.split(_split).where((w) => w.isNotEmpty).toList();
    }
    return _lastWords;
  }

  /// Whether folded [token] is told in folded [text] (EN / RU / other).
  /// A phrase must appear as written, on word boundaries.
  static bool mentions(String text, String token, String language) {
    if (token.isEmpty) return false;
    if (token.contains(_split)) return _phrase(text, token);
    return words(text).any((w) => inflected(w, token, language));
  }

  /// [a] and [b] are the same word up to an inflection of [language].
  static bool inflected(String a, String b, String language) {
    if (a == b) return true;
    return switch (language) {
      'en' => _englishBase(a) == _englishBase(b),
      'ru' => _russianSame(a, b),
      _ => false,
    };
  }

  /// Long words sharing six or more leading letters — general grounding
  /// only (paraphrase), never symbol or image evidence.
  static bool sharesLongStem(String a, String b) {
    if (a.length < 6 || b.length < 6) return false;
    return a.substring(0, 6) == b.substring(0, 6);
  }

  static String _englishBase(String w) {
    var base = w;
    for (final tail in _enTails) {
      if (w.endsWith(tail) && w.length - tail.length >= 3) {
        base = w.substring(0, w.length - tail.length);
        break;
      }
    }
    if (base.length >= 4 && base.endsWith('e')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }

  static bool _russianSame(String a, String b) {
    final n = a.length < b.length ? a.length : b.length;
    var common = 0;
    while (common < n && a[common] == b[common]) {
      common++;
    }
    for (var k = common; k >= 3; k--) {
      if (_ruEndings.contains(a.substring(k)) &&
          _ruEndings.contains(b.substring(k))) {
        return true;
      }
    }
    return false;
  }

  static bool _phrase(String text, String phrase) {
    bool boundary(int at) =>
        at < 0 || at >= text.length || _split.hasMatch(text[at]);
    var at = text.indexOf(phrase);
    while (at != -1) {
      if (boundary(at - 1) && boundary(at + phrase.length)) return true;
      at = text.indexOf(phrase, at + 1);
    }
    return false;
  }
}
