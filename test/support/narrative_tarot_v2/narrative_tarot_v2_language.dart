/// Phase 2.1 CONTRACT HARNESS — offline dominant-language check.
///
/// Not a full NLP classifier. Bounded script + function-word evidence only.
library;

abstract final class Ntv2LanguageContract {
  static const trFunction = {
    've',
    'bir',
    'bu',
    'şu',
    'ile',
    'için',
    'icin',
    'ama',
    'çünkü',
    'cunku',
    'değil',
    'degil',
    'neden',
    'nasıl',
    'nasil',
    'sen',
    'sana',
    'kendine',
    'olan',
    'gibi',
    'çok',
    'cok',
    'daha',
    'olarak',
    'var',
    'yok',
    'ne',
    'ki',
    'da',
    'de',
    'ya',
    'veya',
    'içinde',
    'kadar',
    'sonra',
    'önce',
    'once',
    'şimdi',
    'simdi',
  };

  static const enFunction = {
    'the',
    'and',
    'you',
    'your',
    'this',
    'that',
    'with',
    'for',
    'but',
    'because',
    'not',
    'what',
    'why',
    'how',
    'is',
    'are',
    'a',
    'an',
    'to',
    'of',
    'in',
    'on',
    'it',
    'as',
    'be',
    'or',
    'from',
    'can',
    'will',
    'without',
    'about',
    'into',
    'than',
    'then',
  };

  static const ruFunction = {
    'и',
    'в',
    'не',
    'на',
    'что',
    'это',
    'как',
    'но',
    'а',
    'с',
    'по',
    'для',
    'от',
    'к',
    'он',
    'она',
    'они',
    'мы',
    'вы',
    'я',
    'есть',
    'нет',
    'или',
    'если',
    'когда',
    'чтобы',
    'между',
    'ещё',
    'еще',
    'уже',
    'то',
    'так',
  };

  static final _tokenRe = RegExp(
    r"[A-Za-zА-Яа-яЁёİıĞğÜüŞşÖöÇç]+",
    unicode: true,
  );

  /// Strip stable ids / card tokens so they do not skew language evidence.
  static String scrub(String text) {
    return text
        .replaceAll(
          RegExp(r'\b(?:major|wands|cups|swords|pentacles)_\d{2}\b'),
          ' ',
        )
        .replaceAll(RegExp(r'\b(?:rel|mem|rec)_[A-Za-z0-9_]+\b'), ' ');
  }

  static bool isMismatch(String locale, String raw) {
    final text = scrub(raw);
    final tokens = _tokenRe
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .where((t) => t.length > 1)
        .toList();
    if (tokens.isEmpty) return false;

    final cyr = RegExp(r'[А-Яа-яЁё]').allMatches(text).length;
    final latin = RegExp(r'[A-Za-z]').allMatches(text).length;
    final trChars = RegExp(r'[ğüşöçıİĞÜŞÖÇ]').allMatches(text).length;
    final letters = cyr + latin;
    if (letters < 40) return false;

    final enHits = tokens.where(enFunction.contains).length;
    final trHits = tokens.where(trFunction.contains).length;
    final ruHits = tokens.where(ruFunction.contains).length;

    if (locale == 'tr') {
      // Dominant English function-word evidence fails TR.
      if (enHits >= 5 && enHits > trHits + 2) return true;
      if (enHits >= 8 && trHits <= 2 && trChars == 0) return true;
      // Long Latin prose with almost no TR evidence.
      if (latin > 120 && trHits <= 1 && trChars == 0 && enHits >= 3) {
        return true;
      }
      return false;
    }

    if (locale == 'en') {
      if (cyr > latin * 0.35 && cyr > 25) return true;
      if (trHits >= 5 && trHits > enHits) return true;
      if (trChars >= 4 && trHits >= 3 && enHits <= trHits) return true;
      // Diacritic-light Turkish still fails via function words.
      if (trHits >= 6 && enHits <= 3) return true;
      return false;
    }

    if (locale == 'ru') {
      final cyrRatio = letters == 0 ? 0.0 : cyr / letters;
      // One Russian sentence must not rescue English-majority prose.
      if (cyrRatio < 0.55 && latin > 80) return true;
      if (cyrRatio < 0.45) return true;
      if (enHits >= 6 && ruHits <= 2 && cyrRatio < 0.7) return true;
      return false;
    }

    return false;
  }
}
