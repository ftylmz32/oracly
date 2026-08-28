/// Visual resemblance from real marks. Never a dictionary card.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/l10n/l10n.dart';
import '../data/coffee_symbol_lexicon.dart';
import '../models/coffee_symbol.dart';
import 'coffee_cup_region.dart';
import 'coffee_fortune_beats.dart';

abstract final class CoffeeFortuneVisual {
  CoffeeFortuneVisual._();

  static String opening({
    required int seed,
    required List<String> names,
    required List<CoffeeSymbolSense> senses,
    required List<CoffeeSymbol> firm,
    required List<CoffeeSymbol> faint,
    required String observation,
    required String fallback,
  }) {
    if (senses.isEmpty) {
      if (faint.isNotEmpty) return CoffeeFortuneBeats.hedge(_faint(faint.first));
      final seen = observation.isNotEmpty ? observation : fallback;
      return FortuneVoice.scrub(seen);
    }
    final shapes = [
      for (var i = 0; i < senses.length; i++)
        _shape(
          senses[i],
          names.length > i ? names[i] : senses[i].aliases.first,
          _trust(firm, senses[i]),
        ),
    ];
    final place = CoffeeCupRegion.place(observation);
    if (shapes.length > 1) {
      return CoffeeFortuneBeats.together(
        seed: seed,
        first: shapes[0],
        second: shapes[1],
        place: place,
      );
    }
    return CoffeeFortuneBeats.look(
      seed: seed,
      seen: shapes.first,
      place: place,
    );
  }

  static CoffeeMarkTrust _trust(
    List<CoffeeSymbol> firm,
    CoffeeSymbolSense sense,
  ) {
    for (final symbol in firm) {
      if (CoffeeSymbolLexicon.match(symbol.name)?.id == sense.id) {
        return symbol.trust;
      }
    }
    return CoffeeMarkTrust.mid;
  }

  static String _shape(
    CoffeeSymbolSense sense,
    String name,
    CoffeeMarkTrust trust,
  ) {
    final key = trust == CoffeeMarkTrust.high
        ? 'cup.form.${sense.id}'
        : 'cup.shape.${sense.id}';
    final phrase = OraclyL10n.t(key);
    if (phrase == key) return name;
    return phrase;
  }

  static String _faint(CoffeeSymbol symbol) {
    final sense = CoffeeSymbolLexicon.match(symbol.name);
    if (sense == null) return symbol.name.trim();
    final phrase = OraclyL10n.t('cup.shape.${sense.id}');
    return phrase == 'cup.shape.${sense.id}' ? symbol.name.trim() : phrase;
  }
}
