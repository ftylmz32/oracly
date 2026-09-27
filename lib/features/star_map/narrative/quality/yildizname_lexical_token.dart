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

import 'yildizname_lexical_suffixes.dart';

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

  /// `ay` (Moon, TR) collides with real Turkish words that merely START with
  /// the same two letters once any suffix is allowed (`ayrıca`, `ayrıntı`,
  /// `ayrı`). It gets this curated, closed set of legitimate continuations —
  /// the same ones the old dedicated Moon matcher used — instead of every
  /// Turkish case suffix. (`in` is deliberately excluded: `ayin` — rite,
  /// ceremony — is a real unrelated word.)
  static const _ayEndings = ['ı', 'ın', 'a', 'da', 'dan'];

  /// `sun` (Sun, EN) collides with common Turkish verb forms (`sunum`,
  /// `sunucu`, `sunuş`, `sunmak` — to present/offer), so it is matched as a
  /// WHOLE word only; English possessive (`Sun's`) already ends the word at
  /// the apostrophe, which is not a word character.
  static const _sunToken = 'sun';

  /// General Turkish case suffixes (genitive / dative / locative / ablative,
  /// with and without the buffer consonant) legitimately attached to a body
  /// name written without an apostrophe (`Güneşin`, `Merkürün`). Longer body
  /// names are unambiguous enough that this closed set cannot form another
  /// real word — unlike `ay` / `sun` above, which get their own narrow lists.
  static const _bodyCaseSuffixes = [
    'ın',
    'in',
    'un',
    'ün',
    'ı',
    'i',
    'u',
    'ü',
    'a',
    'e',
    'da',
    'de',
    'ta',
    'te',
    'dan',
    'den',
    'tan',
    'ten',
  ];

  /// A celestial-body-name occurrence — a real word, never a mere prefix of
  /// a longer, unrelated word (`ay` in `ayrıca`, `sun` in `sunucu`). Cyrillic
  /// stems reuse [sign]'s case-ending handling; Latin names get a closed set
  /// of legitimate suffixes (or none, for the two collision-prone tokens).
  static String body(String token) {
    if (_cyrillic.hasMatch(token)) return sign(token);
    final low = token.toLowerCase();
    if (low == 'ay') return _withEndings(token, _ayEndings);
    if (low == _sunToken) return whole(token);
    return _withEndings(token, _bodyCaseSuffixes);
  }

  /// One of the body [tokens], each a genuine word occurrence.
  static String anyBody(List<String> tokens) =>
      '(?:${tokens.map(body).join('|')})';

  static String _withEndings(String token, List<String> endings) {
    final alt = endings.map(RegExp.escape).join('|');
    return '${start(token)}(?:$alt)?(?!$_word)';
  }

  /// An aspect-word occurrence (`kare`, `karesi`, `trines`, `квадрате`) — a
  /// real word, never the tail of `doctrine` or the head of `kareli` /
  /// `тринадцать`. Russian stems take a closed noun/adjective ending.
  static String aspect(String token) {
    if (_cyrillic.hasMatch(token)) {
      final alt = YildiznameLexicalSuffixes.aspectCyrillic.join('|');
      return '${start(token)}ь?(?:$alt)?(?!$_word)';
    }
    final alt =
        YildiznameLexicalSuffixes.aspectLatin.map(RegExp.escape).join('|');
    return '${start(token)}(?:(?:$alt)(?:$alt)?)?(?!$_word)';
  }

  /// One of the aspect [tokens], each a genuine word occurrence.
  static String anyAspect(List<String> tokens) =>
      '(?:${tokens.map(aspect).join('|')})';

  /// A house word after a house number: `evde` / `evindeki`, `house(s)`,
  /// `доме` — never `evre`, `evren`, `evet`, `household`.
  static String house() => '(?:'
      '${_withEndings('ev', YildiznameLexicalSuffixes.houseEv)}|'
      '${_withEndings('house', const ['s'])}|'
      '${whole('доме')})';

  /// Compiles a pattern built from the helpers above (ignore case).
  static RegExp compile(String source) => RegExp(source, caseSensitive: false);

  /// On some runtimes (JavaScript-backed builds) `toLowerCase()` turns Turkish
  /// `İ` into `i` + U+0307 (combining dot), which would split `İkizler` in two.
  /// Drop the mark so the token matches on every runtime.
  static String normalizeProse(String prose) => prose.replaceAll('\u0307', '');
}
