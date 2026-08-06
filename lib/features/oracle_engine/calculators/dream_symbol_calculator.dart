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
        if (lower.contains(token)) {
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
