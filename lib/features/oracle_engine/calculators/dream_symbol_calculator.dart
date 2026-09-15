/// OR-1140 — Dream token categorization calculator.
library;

import '../core/oracle_engine_type.dart';
import '../models/dream_reading.dart';

abstract class DreamSymbolCalculator {
  List<DreamSymbolMatch> categorize(String rawText);
}

class LexiconDreamSymbolCalculator implements DreamSymbolCalculator {
  LexiconDreamSymbolCalculator({Map<DreamSymbolCategory, Set<String>>? lexicon})
      : _lexicon = lexicon ?? _defaultLexicon;

  final Map<DreamSymbolCategory, Set<String>> _lexicon;

  static final _defaultLexicon = {
    DreamSymbolCategory.animals: {'kedi', 'köpek', 'kuş', 'yılan', 'at'},
    DreamSymbolCategory.colors: {'kırmızı', 'mavi', 'siyah', 'beyaz', 'altın'},
    DreamSymbolCategory.places: {'ev', 'deniz', 'dağ', 'orman', 'şehir'},
    DreamSymbolCategory.emotions: {'korku', 'sevinç', 'huzur', 'kaygı'},
    DreamSymbolCategory.religious: {'cami', 'kilise', 'dua', 'melek'},
    DreamSymbolCategory.psychological: {'düşmek', 'koşmak', 'uçmak'},
    DreamSymbolCategory.objects: {'kapı', 'anahtar', 'su', 'ateş'},
    DreamSymbolCategory.symbols: {'ay', 'güneş', 'yıldız'},
  };

  @override
  List<DreamSymbolMatch> categorize(String rawText) {
    final lower = rawText.toLowerCase();
    final matches = <DreamSymbolMatch>[];

    for (final entry in _lexicon.entries) {
      for (final token in entry.value) {
        if (_hasWord(lower, token)) {
          matches.add(
            DreamSymbolMatch(
              token: token,
              category: entry.key,
              confidence: 1.0,
            ),
          );
        }
      }
    }
    return matches;
  }

  /// True if [token] occurs in [text] at a real word start -- e.g. "tren"
  /// matches inside "trenin"/"treni" (Turkish inflects by suffixing only),
  /// but "at" does not match inside "saat" and "ay" does not match inside
  /// "ray"/"raylar", because a genuine match can never have a letter
  /// immediately before it.
  static bool _hasWord(String text, String token) {
    if (token.isEmpty) return false;
    var index = text.indexOf(token);
    while (index != -1) {
      final before = index == 0 ? null : text[index - 1];
      if (before == null || !_isTurkishLetter(before)) return true;
      index = text.indexOf(token, index + 1);
    }
    return false;
  }

  static bool _isTurkishLetter(String char) =>
      RegExp(r'[a-zçğıöşü]', unicode: true).hasMatch(char);
}
