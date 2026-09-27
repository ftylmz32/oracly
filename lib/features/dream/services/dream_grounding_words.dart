/// TR / EN / RU word tools for Dream grounding — explicit alphabets only.
library;

import '../../../core/l10n/app_locale.dart';
import '../../../core/text/turkish_lexical_matcher.dart';
import 'dream_word_forms.dart';

abstract final class DreamGroundingWords {
  DreamGroundingWords._();

  /// Folded letters kept by the tokenizer: Latin, Turkish, Cyrillic, digits.
  static const _letters = 'a-z0-9çğöşüâîûа-яё';
  static final _split = RegExp('[^$_letters]+');

  static const tr = {
    'için', 'gibi', 'olan', 'daha', 'kadar', 'sonra', 'onlar', 'bunu',
    'şunu', 'senin', 'sana', 'seni', 'bana', 'beni', 'olarak', 'olabilir',
    'belki', 'değil', 'şimdi', 'sanki', 'içinde', 'diye', 'neden', 'nasıl',
    'hangi', 'bile', 'çünkü', 'ancak', 'fakat', 'yine', 'bazen', 'şeyler',
  };

  static const en = {
    'this', 'that', 'with', 'from', 'your', 'have', 'there', 'their',
    'what', 'when', 'where', 'which', 'while', 'about', 'into', 'like',
    'just', 'then', 'than', 'them', 'they', 'were', 'been', 'being', 'some',
    'more', 'very', 'also', 'only', 'even', 'still', 'might', 'could',
    'would', 'should', 'because', 'through', 'something',
  };

  static const ru = {
    'этот', 'этой', 'этом', 'этого', 'который', 'которая', 'которое',
    'когда', 'тогда', 'потом', 'очень', 'будто', 'словно', 'может', 'можно',
    'тебя', 'тебе', 'твой', 'твоя', 'твое', 'твоем', 'меня', 'было', 'была',
    'были', 'быть', 'есть', 'чтобы', 'только', 'даже', 'если', 'здесь',
    'него', 'себя', 'свой', 'своей',
  };

  /// Lowercase + fold dotted/dotless i and ё so spelling variants compare.
  static String fold(String value) => value
      .toLowerCase()
      .replaceAll('\u0307', '')
      .replaceAll('ı', 'i')
      .replaceAll('ё', 'е');

  /// Words of four or more letters that can carry meaning. Connectors and
  /// the word "dream" itself never count — both appear in any reading.
  static Set<String> significant(String value) => fold(value)
      .split(_split)
      .where((w) => w.length >= 4 && !_isConnector(w))
      .toSet();

  static bool overlaps(Set<String> text, Set<String> told, String language) =>
      text.any((w) => told.any((t) => sameWord(w, t, language)));

  /// General grounding — a paraphrase still touches the told dream: the
  /// same word, the same word inflected in [language], or two long words
  /// sharing six leading letters. Short accidental prefixes never count
  /// ("yedi" / "yedim", "sea" / "season").
  static bool sameWord(String a, String b, String language) {
    if (a == b) return true;
    if (DreamWordForms.sharesLongStem(a, b)) return true;
    if (language != AppLocale.tr) {
      return DreamWordForms.inflected(a, b, language);
    }
    return TurkishLexicalMatcher.inflects(a, b) ||
        TurkishLexicalMatcher.inflects(b, a);
  }

  /// Strict evidence — [token] is told as a word of [language]: Turkish
  /// with a supported inflection only ("suyun", never "sunum"); English
  /// with -s / -es / -ed / -ing only ("red" is not in "reduce"); Russian
  /// with a case ending only.
  static bool mentions(String text, String token, String language) {
    if (language == AppLocale.tr) {
      return TurkishLexicalMatcher.mentions(text, token);
    }
    return DreamWordForms.mentions(fold(text), fold(token).trim(), language);
  }

  static bool _isConnector(String w) =>
      tr.contains(w) ||
      en.contains(w) ||
      ru.contains(w) ||
      w.startsWith('rüya') ||
      w.startsWith('ruya') ||
      w.startsWith('dream') ||
      w.startsWith('сновид') ||
      w == 'снов' ||
      w == 'сном' ||
      w == 'снах';
}
