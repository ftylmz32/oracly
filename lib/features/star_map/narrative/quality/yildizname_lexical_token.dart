/// Boundary-aware lexical tokens for Narrative grounding (TR / EN / RU).
///
/// Body and sign tokens used to be spliced into regexes as raw substrings, so
/// the Turkish sign token `yay` (Sagittarius) matched inside `dünyaya` (to the
/// world), and a correct "Terazi yükselen, dünyaya …" was rejected as a wrong
/// Ascendant. A token must now be a real word occurrence.
///
/// The word-character class is EXPLICIT (Latin incl. Turkish `çğıöşü İ`,
/// Cyrillic, digits, combining marks) — an ASCII-only `\b` would treat Turkish
/// and Russian letters as boundaries. It is deliberately NOT `\p{L}` with the
/// `unicode` flag: compiling those patterns on every validation cost ~10 s
/// (on-device: a frozen UI), whereas this class is as fast as plain ASCII.
library;

abstract final class YildiznameLexicalToken {
  YildiznameLexicalToken._();

  /// Letters / digits / `_` / combining marks of the supported languages.
  static const _word = r'[0-9A-Za-z_\u00C0-\u024F\u0300-\u036F\u0400-\u04FF]';

  static final _cyrillic = RegExp(r'[\u0400-\u04FF]');

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

  /// One of the sign [tokens], each a whole word.
  static String anySign(List<String> tokens) =>
      '(?:${tokens.map(sign).join('|')})';

  /// Compiles a pattern built from the helpers above (ignore case).
  static RegExp compile(String source) =>
      RegExp(source, caseSensitive: false);

  /// On some runtimes (JavaScript-backed builds) `toLowerCase()` turns Turkish
  /// `İ` into `i` + U+0307 (combining dot), which would split `İkizler` in two.
  /// Drop the mark so the token matches on every runtime.
  static String normalizeProse(String prose) => prose.replaceAll('\u0307', '');
}
