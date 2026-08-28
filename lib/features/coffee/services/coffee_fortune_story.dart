/// Cup story: look → beside → meaning → you → possible move → optional ask.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../models/coffee_reading.dart';
import '../models/coffee_symbol.dart';
import '../data/coffee_symbol_lexicon.dart';
import '../data/coffee_symbol_pairs.dart';
import 'coffee_fortune_beats.dart';
import 'coffee_fortune_life.dart';
import 'coffee_fortune_visual.dart';

abstract final class CoffeeFortuneStory {
  CoffeeFortuneStory._();

  static String build(
    CoffeeReading raw,
    List<CoffeeSymbolSense> senses, {
    List<String> themes = const [],
    List<CoffeeSymbol> faint = const [],
    List<CoffeeSymbol> firm = const [],
  }) {
    final names = _names(raw, senses);
    final observation = FortuneVoice.scrub(raw.visualObservation);
    final fallback = FortuneVoice.scrub(raw.overall);
    final seed = Object.hash(raw.id, names.join('|'), observation).abs();
    final ids = {for (final s in senses) s.id};
    final opening = CoffeeFortuneVisual.opening(
      seed: seed,
      names: names,
      senses: senses,
      firm: firm,
      faint: faint,
      observation: observation,
      fallback: fallback,
    );
    if (opening.isEmpty) return '';
    final parts = <String>[opening];
    final cupAside = _cupAside(observation, opening);
    if (cupAside != null) parts.add(cupAside);
    if (senses.isNotEmpty) parts.add(_meaning(senses, names));
    final life = CoffeeFortuneLife.phrase(ids, themes);
    if (life.isNotEmpty) parts.add(life);
    final move = CoffeeFortuneBeats.develop(
      observation: observation,
      ids: ids,
      seen: names.isNotEmpty ? names.first : opening,
      seed: seed,
    );
    if (move.isNotEmpty) parts.add(move);
    // Rare reflective leave-note — never quiz the reader.
    if (firm.isNotEmpty && seed % 7 == 0) {
      final leave = CoffeeFortuneBeats.ask(ids, themes, seed);
      if (leave.isNotEmpty) parts.add(leave);
    }
    return HumanReader.guard(FortuneVoice.joinSentences(parts, max: 8));
  }

  /// Keeps a short real visual note when vision wrote more than shape labels.
  static String? _cupAside(String observation, String opening) {
    final seen = observation.trim();
    if (seen.length < 28) return null;
    final lower = seen.toLowerCase();
    final open = opening.toLowerCase();
    final headLen = lower.length < 16 ? lower.length : 16;
    if (headLen >= 8 && open.contains(lower.substring(0, headLen))) {
      return null;
    }
    const cues = [
      'yanında',
      'açıklık',
      'yoğun',
      'ince',
      'küme',
      'beside',
      'dense',
      'рядом',
      'густ',
    ];
    if (!cues.any(lower.contains)) return null;
    final clip = seen.length <= 110 ? seen : '${seen.substring(0, 107).trim()}.';
    return FortuneVoice.scrub(clip);
  }

  static String _meaning(
    List<CoffeeSymbolSense> senses,
    List<String> names,
  ) {
    final weave = CoffeeSymbolPairs.weave(senses, names);
    final extra = CoffeeSymbolPairs.third(senses, names);
    if (extra == null) return weave;
    return '$weave $extra';
  }

  static List<String> _names(
    CoffeeReading raw,
    List<CoffeeSymbolSense> senses,
  ) {
    final names = <String>[];
    for (final sense in senses) {
      var hit = '';
      for (final symbol in raw.symbols) {
        if (CoffeeSymbolLexicon.match(symbol.name)?.id == sense.id &&
            symbol.trust.isFirm) {
          hit = symbol.name.trim();
          break;
        }
      }
      names.add(hit.isEmpty ? sense.aliases.first : hit);
    }
    return names;
  }
}
