/// Combines actually present symbols. Never invents a missing mark.
library;

import '../../../core/l10n/l10n.dart';
import 'coffee_symbol_lexicon.dart';

abstract final class CoffeeSymbolPairs {
  CoffeeSymbolPairs._();

  static String weave(
    List<CoffeeSymbolSense> senses,
    List<String> names,
  ) {
    if (senses.isEmpty) return '';
    if (senses.length == 1) {
      return OraclyL10n.t('fortune.cup.single')
          .replaceAll('{meaning}', senses.first.meaning);
    }
    final ids = {for (final s in senses) s.id};
    final a = names.isNotEmpty ? names.first : senses.first.aliases.first;
    final b = names.length > 1 ? names[1] : senses[1].aliases.first;
    final key = _pairKey(ids);
    if (key != null) {
      return OraclyL10n.t(key).replaceAll('{a}', a).replaceAll('{b}', b);
    }
    return OraclyL10n.t('fortune.cup.together')
        .replaceAll('{a}', a)
        .replaceAll('{b}', b);
  }

  static String? third(List<CoffeeSymbolSense> senses, List<String> names) {
    if (senses.length < 3 || names.length < 3) return null;
    final tone = _tone(senses[2]);
    return OraclyL10n.t('fortune.cup.third')
        .replaceAll('{c}', names[2])
        .replaceAll('{tone}', tone);
  }

  static String _tone(CoffeeSymbolSense sense) {
    const love = {'heart', 'ring', 'person'};
    const work = {'key', 'mountain', 'letter', 'road'};
    if (love.contains(sense.id)) {
      return OraclyL10n.t('fortune.cup.tone.love');
    }
    if (work.contains(sense.id)) {
      return OraclyL10n.t('fortune.cup.tone.work');
    }
    return sense.meaning;
  }

  static String? _pairKey(Set<String> ids) {
    if (ids.contains('bird') && ids.contains('road')) {
      return 'fortune.cup.pair.bird_road';
    }
    if (ids.contains('heart') && ids.contains('ring')) {
      return 'fortune.cup.pair.heart_ring';
    }
    if (ids.contains('road') && ids.contains('key')) {
      return 'fortune.cup.pair.road_key';
    }
    if (ids.contains('mountain') && ids.contains('star')) {
      return 'fortune.cup.pair.mountain_star';
    }
    return null;
  }
}
