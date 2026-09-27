/// Turkish word evidence: a token counts only at a real word start and only
/// as itself or with a supported inflection ([TurkishInflection]).
///
/// "ev" is in "evde", "evlerde", "Evdeydim" — never in "evren", "evet" or
/// "sevgi". "su" is in "suyun", never in "sunum". This is the one Turkish
/// matcher for observed evidence; a false hit here would become a symbol,
/// a place, a person, provider evidence and a grounding pass at once.
library;

import 'turkish_inflection.dart';

abstract final class TurkishLexicalMatcher {
  TurkishLexicalMatcher._();

  static final _letter = RegExp(r'\p{L}', unicode: true);
  static const _apostrophes = "'’";
  static const _clauseEnd = '.!?,;:…';
  static const _clauseWords = {'ve', 'ama', 'fakat', 'sonra'};

  /// Bare forms that are also a clause-final verb ("yemek yedi." — ate).
  static const _verbHomographs = {'yedi'};

  /// Turkish lowercase: I → ı, İ → i, combining dot dropped.
  static String normalize(String value) => value
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase()
      .replaceAll('\u0307', '');

  /// Whether [token] occurs in [text] as a told word. Both are normalized.
  static bool mentions(String text, String token) =>
      occursIn(normalize(text), normalize(token).trim());

  /// Whether [token] occurs in already [normalize]d [text] as a word: a
  /// word start, then the token and only a supported inflection (after an
  /// apostrophe too: "Ay'ı").
  static bool occursIn(String text, String token) {
    if (token.isEmpty) return false;
    if (_scan(text, token, token, vowelFirst: false)) return true;
    for (final alt in TurkishInflection.alternates(token)) {
      if (_scan(text, alt, token, vowelFirst: true)) return true;
    }
    return false;
  }

  /// Whether the single [word] is [stem] itself or [stem] inflected.
  static bool inflects(String word, String stem) {
    if (word == stem) return true;
    if (stem.isEmpty) return false;
    if (word.startsWith(stem) &&
        TurkishInflection.accepts(word.substring(stem.length), stem)) {
      return true;
    }
    for (final alt in TurkishInflection.alternates(stem)) {
      if (!word.startsWith(alt) || word.length == alt.length) continue;
      final tail = word.substring(alt.length);
      if (TurkishInflection.isVowel(tail[0]) &&
          TurkishInflection.accepts(tail, stem)) {
        return true;
      }
    }
    return false;
  }

  static bool _scan(
    String text,
    String needle,
    String token, {
    required bool vowelFirst,
  }) {
    var at = text.indexOf(needle);
    while (at != -1) {
      if (at == 0 || !_isLetter(text, at - 1)) {
        final end = at + needle.length;
        final tail = _tail(text, end);
        final shaped = !vowelFirst ||
            (tail.isNotEmpty && TurkishInflection.isVowel(tail[0]));
        if (shaped &&
            TurkishInflection.accepts(tail, token) &&
            !(tail.isEmpty && _isClauseFinalVerb(text, end, token))) {
          return true;
        }
      }
      at = text.indexOf(needle, at + 1);
    }
    return false;
  }

  /// Letters right after [end]; after an apostrophe the suffix continues.
  static String _tail(String text, int end) {
    var from = end;
    if (from + 1 < text.length &&
        _apostrophes.contains(text[from]) &&
        _isLetter(text, from + 1)) {
      from++;
    }
    var to = from;
    while (to < text.length && _isLetter(text, to)) {
      to++;
    }
    return to == from ? '' : text.substring(from, to);
  }

  static bool _isClauseFinalVerb(String text, int end, String token) {
    if (!_verbHomographs.contains(token)) return false;
    var i = end;
    while (i < text.length && text[i] == ' ') {
      i++;
    }
    if (i >= text.length || _clauseEnd.contains(text[i])) return true;
    final next = _tail(text, i);
    return _clauseWords.contains(next);
  }

  static bool _isLetter(String text, int at) => _letter.hasMatch(text[at]);
}
