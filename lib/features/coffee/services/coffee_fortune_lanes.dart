/// Real parser asides. Empty strings stay empty. Never invent tiles.
library;

import '../../../core/copy/fortune_voice.dart';
import '../models/coffee_reading.dart';
import '../data/coffee_symbol_lexicon.dart';

abstract final class CoffeeFortuneLanes {
  CoffeeFortuneLanes._();

  static const _love = {'heart', 'ring', 'person'};
  static const _work = {'key'};
  static const _news = {'bird', 'letter'};
  static const _path = {'road'};
  static const _caution = {'mountain', 'eye'};

  static String love(CoffeeReading raw, List<CoffeeSymbolSense> senses) {
    if (!_has(senses, _love)) return '';
    return _aside(raw.love);
  }

  static String work(CoffeeReading raw, List<CoffeeSymbolSense> senses) {
    if (!_has(senses, _work)) return '';
    return _aside(raw.career);
  }

  static String news(CoffeeReading raw, List<CoffeeSymbolSense> senses) {
    if (!_has(senses, _news)) return '';
    return _aside(raw.nearFuture);
  }

  static String path(CoffeeReading raw, List<CoffeeSymbolSense> senses) {
    if (!_has(senses, _path)) return '';
    if (_has(senses, _work) || _has(senses, _news)) return '';
    final career = _aside(raw.career);
    return career.isNotEmpty ? career : _aside(raw.nearFuture);
  }

  static String caution(CoffeeReading raw, List<CoffeeSymbolSense> senses) {
    if (!_has(senses, _caution)) return '';
    final body = _aside(raw.takeaway);
    if (body.isEmpty) return '';
    final lower = body.toLowerCase();
    if (lower.contains('sorman') || body.contains('?')) return '';
    return body;
  }

  static bool _has(List<CoffeeSymbolSense> senses, Set<String> ids) {
    return senses.any((s) => ids.contains(s.id));
  }

  static String _aside(String source) {
    final body = FortuneVoice.scrub(source);
    if (body.isEmpty || FortuneVoice.looksRobotic(source)) return '';
    return body;
  }
}
