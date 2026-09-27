/// Boundary-aware lexical tokens for Narrative grounding (TR / EN / RU).
///
/// Body and sign tokens used to be spliced into regexes as raw substrings, so
/// the Turkish sign token `yay` (Sagittarius) matched inside `dünyaya` (to the
/// world), and a correct "Terazi yükselen, dünyaya …" was rejected as a wrong
/// Ascendant. A token must now be a real word occurrence. Boundaries are
/// Unicode-aware — `\p{L}` covers Turkish `ğüşıöç İ` and Cyrillic — so an
/// ASCII-only `\b` cannot create new Turkish / Russian false positives.
library;

abstract final class YildiznameLexicalToken {
  YildiznameLexicalToken._();

  /// Any Unicode letter, combining mark or digit (plus `_`).
  static const _word = r'[\p{L}\p{M}\p{N}_]';

  static final _cyrillic = RegExp(r'[Ѐ-ӿ]');

  /// Russian case endings that legitimately follow a sign stem
  /// (Скорпион-е, Скорпион-ом, Рак-а). Latin (TR / EN) names take none:
  /// Turkish attaches suffixes after an apostrophe (`Aslan'da`), which is not
  /// a letter, so it already satisfies the end boundary.
  static const _cyrillicEnding =
      '(?:ом|ем|ой|ей|ах|ях|ам|ям|ов|ев|а|у|ы|е|и|я|ю|о)?';

  /// A word START. Inflection may follow (`güneşin`, `ayın`, `асцендента`),
  /// but the token can never begin in the middle of a longer word.
  static String start(String token) => '(?<!$_word)${RegExp.escape(token)}';

  /// One of [tokens], each starting a word.
  static String anyStart(List<String> tokens) =>
      '(?:${tokens.map(start).join('|')})';

  /// A WHOLE word: starts and ends on a word boundary (`mc`, `midheaven`).
  static String whole(String token) => '${start(token)}(?!$_word)';

  /// A zodiac-sign occurrence — a real word, not a substring of a larger
  /// alphabetic word (`yay` in `dünyaya` / `yayın` / `yaygın`, `koç` in
  /// `koçluk`, `leo` in `Leonardo`). Cyrillic stems may take a case ending.
  static String sign(String token) {
    final ending = _cyrillic.hasMatch(token) ? _cyrillicEnding : '';
    return '${start(token)}$ending(?!$_word)';
  }

  /// Compiles a pattern built from the helpers above (Unicode + ignore case).
  static RegExp compile(String source) =>
      RegExp(source, caseSensitive: false, unicode: true);

  /// On some runtimes (JavaScript-backed builds) `toLowerCase()` turns Turkish
  /// `İ` into `i` + U+0307 (combining dot), which would split `İkizler` in two.
  /// Drop the mark so the token matches on every runtime.
  static String normalizeProse(String prose) => prose.replaceAll('̇', '');
}
