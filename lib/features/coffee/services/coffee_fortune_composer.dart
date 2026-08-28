/// Grounds coffee copy in vision symbols. Never invents unseen marks.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/coffee_reading.dart';
import '../models/coffee_symbol.dart';
import '../data/coffee_symbol_lexicon.dart';
import 'coffee_fortune_lanes.dart';
import 'coffee_fortune_story.dart';

abstract final class CoffeeFortuneComposer {
  CoffeeFortuneComposer._();

  static CoffeeReading compose(
    CoffeeReading raw, {
    List<String> themes = const [],
  }) {
    final firm = raw.symbols.where((s) => s.trust.isFirm).toList();
    final faint = raw.symbols.where((s) => !s.trust.isFirm).toList();
    final senses = CoffeeSymbolLexicon.presentIn(
      names: firm.map((s) => s.name),
    );
    return CoffeeReading(
      id: raw.id,
      createdAt: raw.createdAt,
      imagePath: raw.imagePath,
      visualObservation: FortuneVoice.scrub(raw.visualObservation),
      overall: CoffeeFortuneStory.build(
        raw,
        senses,
        themes: themes,
        faint: faint,
        firm: firm,
      ),
      love: CoffeeFortuneLanes.love(raw, senses),
      career: CoffeeFortuneLanes.work(raw, senses),
      money: '',
      nearFuture: _near(raw, senses),
      takeaway: CoffeeFortuneLanes.caution(raw, senses),
      symbols: [
        for (final s in firm) _ground(s, senses),
        ...faint,
      ],
    );
  }

  static String _near(CoffeeReading raw, List<CoffeeSymbolSense> senses) {
    final news = CoffeeFortuneLanes.news(raw, senses);
    return news.isNotEmpty ? news : CoffeeFortuneLanes.path(raw, senses);
  }

  static CoffeeSymbol _ground(
    CoffeeSymbol symbol,
    List<CoffeeSymbolSense> senses,
  ) {
    final sense = CoffeeSymbolLexicon.match(symbol.name);
    if (sense == null) {
      return CoffeeSymbol(
        name: symbol.name,
        meaning: FortuneVoice.scrub(symbol.meaning),
        interpretation: FortuneVoice.scrub(symbol.interpretation),
        trust: symbol.trust,
      );
    }
    // Prefer what vision actually wrote; lexicon only fills empty gaps.
    final vision = FortuneVoice.scrub(symbol.interpretation);
    final meaning = vision.isNotEmpty
        ? vision
        : FortuneVoice.scrub(symbol.meaning).isNotEmpty
            ? FortuneVoice.scrub(symbol.meaning)
            : sense.meaning;
    return CoffeeSymbol(
      name: symbol.name,
      meaning: sense.meaning,
      interpretation: meaning,
      trust: symbol.trust,
    );
  }
}
