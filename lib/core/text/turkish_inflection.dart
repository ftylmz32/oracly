/// The Turkish inflections a told noun may carry — and nothing else.
///
/// Suffixes are harmony-agnostic (both vowel sets are accepted) and cover
/// plural, possessive, case, the relative "-ki" and the y-copula. Derivation
/// is never accepted: "evli" is not "ev", "huzursuz" is not "huzur". Tables
/// hold both "ı" and "i" forms, so Turkish-lowercased and ı→i folded words
/// parse alike.
library;

abstract final class TurkishInflection {
  TurkishInflection._();

  static const _vowels = 'aeıioöuüâîû';

  /// Numerals take case endings only: "yediyi", "yedide" — never "yedim"
  /// (I ate) or "yediler" (they ate).
  static const _numerals = {
    'iki', 'üç', 'dört', 'beş', 'altı', 'alti', 'yedi', 'sekiz', 'dokuz',
    'yirmi', 'otuz', 'kırk', 'kirk', 'elli', 'altmış', 'altmiş', 'yetmiş',
    'seksen', 'doksan',
  };

  /// Inflected forms coincide with another word ("altında" = under it),
  /// so only the bare word or its plural counts.
  static const _bareOrPlural = {'altın', 'altin'};

  /// Nouns that drop their last vowel before a vowel suffix ("şehre").
  static const _dropped = {
    'şehir': 'şehr', 'ağız': 'ağz', 'ağiz': 'ağz', 'burun': 'burn',
    'oğul': 'oğl', 'isim': 'ism', 'resim': 'resm', 'akıl': 'akl',
    'akil': 'akl', 'fikir': 'fikr', 'karın': 'karn', 'karin': 'karn',
    'boyun': 'boyn', 'gönül': 'gönl',
  };

  static const _soft = {'p': 'b', 'ç': 'c', 't': 'd', 'k': 'ğ'};

  static final _plural = _x(['lAr']);
  static final _possC = _x(['Im', 'ImIz', 'In', 'InIz']);
  static final _possV = _x(['m', 'mIz', 'nIz', 'yIm']);
  static final _poss3C = _x(['I']);
  static final _poss3V = _x(['sI', 'yI']);
  static final _loc = _x(['DA']), _locN = _x(['ndA']);
  static final _abl = _x(['DAn']), _ablN = _x(['ndAn']);
  static final _datC = _x(['A']), _datV = _x(['yA']), _datN = _x(['nA']);
  static final _accC = _x(['I']), _accV = _x(['yI']), _accN = _x(['nI']);
  static final _genC = _x(['In']), _genV = _x(['nIn', 'yIn']);
  static final _insC = _x(['lA']), _insV = _x(['ylA']);
  static const _ki = ['ki'];
  static final _cop = _x(['ydI', 'ymIş', 'yken', 'yIm', 'yIz', 'DIr', 'ysA']);
  static final _person = _x(['m', 'n', 'k', 'nIz', 'lAr']);

  static bool isVowel(String c) => _vowels.contains(c);

  /// Whether [tail] is a supported inflection of the noun [stem] (both
  /// already lowercased). An empty tail is the word itself.
  static bool accepts(String tail, String stem) {
    if (tail.isEmpty) return true;
    if (stem.isEmpty) return false;
    if (_bareOrPlural.contains(stem)) return _plural.contains(tail);
    final start = _numerals.contains(stem) ? _At.numeral : _At.stem;
    return _go(tail, 0, start, isVowel(stem[stem.length - 1]));
  }

  /// Stem shapes used only before a vowel-initial suffix: consonant
  /// softening ("köpeği", "çocuğu") and vowel drop ("şehre").
  static List<String> alternates(String stem) {
    final dropped = _dropped[stem];
    if (dropped != null) return [dropped];
    if (stem.length < 3 || _numerals.contains(stem)) return const [];
    final soft = _soft[stem[stem.length - 1]];
    final vowels = stem.split('').where(isVowel).length;
    if (soft == null || vowels < 2) return const [];
    return [stem.substring(0, stem.length - 1) + soft];
  }

  static bool _go(String s, int i, _At at, bool vowelEnd) {
    if (i == s.length) return true;
    bool next(List<String> forms, _At to) {
      for (final f in forms) {
        if (s.startsWith(f, i) &&
            _go(s, i + f.length, to, isVowel(f[f.length - 1]))) {
          return true;
        }
      }
      return false;
    }

    List<String> pick(_Flavor fl, List<String> c, List<String> v,
            List<String> n) =>
        fl == _Flavor.c ? c : (fl == _Flavor.v ? v : n);

    bool kase(_Flavor fl) =>
        next(fl == _Flavor.n ? _locN : _loc, _At.loc) ||
        next(fl == _Flavor.n ? _ablN : _abl, _At.done) ||
        next(pick(fl, _datC, _datV, _datN), _At.done) ||
        next(pick(fl, _accC, _accV, _accN), _At.done) ||
        next(pick(fl, _genC, _genV, _genV), _At.gen) ||
        next(fl == _Flavor.c ? _insC : _insV, _At.done);

    final flavor = vowelEnd ? _Flavor.v : _Flavor.c;
    return switch (at) {
      _At.stem => next(_plural, _At.plural) ||
          next(vowelEnd ? _possV : _possC, _At.poss) ||
          next(vowelEnd ? _poss3V : _poss3C, _At.poss3) ||
          kase(flavor) ||
          (vowelEnd && next(_cop, _At.cop)),
      _At.numeral => kase(flavor),
      _At.plural => next(_possC, _At.poss) ||
          next(_poss3C, _At.poss3) ||
          kase(_Flavor.c),
      _At.poss => kase(flavor),
      _At.poss3 => kase(_Flavor.n),
      _At.loc => next(_ki, _At.done) || next(_cop, _At.cop),
      _At.gen => next(_ki, _At.done),
      _At.cop => next(_person, _At.done),
      _At.done => false,
    };
  }

  /// Expands I (ı i u ü), A (e a) and D (d t) into every spelling.
  static List<String> _x(List<String> patterns) =>
      [for (final p in patterns) ..._expand(p)];

  static Iterable<String> _expand(String p) sync* {
    final i = p.indexOf(RegExp('[IAD]'));
    if (i < 0) {
      yield p;
      return;
    }
    final options = switch (p[i]) {
      'I' => const ['ı', 'i', 'u', 'ü'],
      'A' => const ['e', 'a'],
      _ => const ['d', 't'],
    };
    for (final o in options) {
      yield* _expand(p.replaceRange(i, i + 1, o));
    }
  }
}

enum _At { stem, numeral, plural, poss, poss3, loc, gen, cop, done }

/// After a consonant, after a vowel, or after a 3rd-person possessive
/// (pronominal "n": "evinde", "kapısını").
enum _Flavor { c, v, n }
