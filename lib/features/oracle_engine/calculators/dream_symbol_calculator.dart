/// OR-1140 — Dream token categorization calculator.
library;

import '../../../core/text/turkish_lexical_matcher.dart';
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

  /// Lexicon tokens told as Turkish words — the token itself or a supported
  /// inflection ("atı", "suyun"), never another word ("ateş", "sunum").
  @override
  List<DreamSymbolMatch> categorize(String rawText) {
    final text = TurkishLexicalMatcher.normalize(rawText);
    final matches = <DreamSymbolMatch>[];

    for (final entry in _lexicon.entries) {
      for (final token in entry.value) {
        if (TurkishLexicalMatcher.occursIn(text, token)) {
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
}
