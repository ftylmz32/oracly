/// TR / EN / RU word tools for Dream grounding — explicit alphabets only.
library;

abstract final class DreamGroundingWords {
  DreamGroundingWords._();

  /// Folded letters kept by the tokenizer: Latin, Turkish, Cyrillic, digits.
  static const _letters = 'a-z0-9çğöşüâîûа-яё';
  static final _split = RegExp('[^$_letters]+');
  static final _letter = RegExp('[$_letters]');

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

  static bool overlaps(Set<String> text, Set<String> told) =>
      text.any((w) => told.any((t) => sameStem(w, t)));

  /// Same word up to an inflectional ending (Turkish suffixes, Russian case
  /// endings, English plurals): shares its first min(5, shorter − 1) letters.
  static bool sameStem(String a, String b) {
    if (a == b) return true;
    final shorter = a.length < b.length ? a.length : b.length;
    final need = shorter - 1 < 5 ? shorter - 1 : 5;
    if (need < 3) return false;
    return a.substring(0, need) == b.substring(0, need);
  }

  /// True when [token] starts a word in [text] (no letter directly before).
  /// Suffixed forms match ("yılanı"); a token hidden inside another word
  /// does not ("su" is not in "masum"). [english] tokens must be the whole
  /// word or its plural ("red" is not in "reduce", "sea" not in "season").
  static bool mentions(String text, String token, {bool english = false}) {
    final hay = fold(text);
    final needle = fold(token).trim();
    if (needle.isEmpty) return false;
    var index = hay.indexOf(needle);
    while (index != -1) {
      final starts = index == 0 || !_letter.hasMatch(hay[index - 1]);
      if (starts && (!english || _endsWord(hay, index + needle.length))) {
        return true;
      }
      index = hay.indexOf(needle, index + 1);
    }
    return false;
  }

  static bool _endsWord(String hay, int end) {
    bool boundary(int at) => at >= hay.length || !_letter.hasMatch(hay[at]);
    if (boundary(end)) return true;
    if (hay[end] == 's' && boundary(end + 1)) return true;
    return hay.startsWith('es', end) && boundary(end + 2);
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
