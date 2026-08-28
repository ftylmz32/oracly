/// Hand story: look → beside → you → mark → one question.
library;

import '../../../core/copy/fortune_voice.dart';
import '../../../core/reading/human_reader.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../data/palm_observation.dart';
import '../models/palm_reading.dart';
import 'palm_fortune_beats.dart';

abstract final class PalmFortuneStory {
  PalmFortuneStory._();

  static String build(PalmReading raw, {List<String> themes = const []}) {
    final heart = PalmObservation.line(raw.heartLine);
    final head = PalmObservation.line(raw.headLine);
    final life = PalmObservation.line(raw.lifeLine);
    final fate = PalmObservation.line(raw.fateLine);
    final lanes = _lanes(heart: heart, head: head, life: life, fate: fate);
    final seen = lanes.values.toList();
    final shape = PalmObservation.shapeOf(raw);
    final marks = PalmObservation.marks(raw.symbols);
    if (shape.isEmpty && seen.isEmpty && marks.isEmpty) {
      return PalmFortuneBeats.hedge();
    }
    final seed = Object.hash(raw.id, raw.hand.name, seen.join('|'), shape).abs();
    final opening = shape.isNotEmpty
        ? shape
        : (seen.isNotEmpty ? seen.first : '');
    final parts = <String>[
      if (opening.isNotEmpty) PalmFortuneBeats.look(seed, opening),
    ];
    if (seen.length >= 2) {
      final keys = lanes.keys.toList();
      parts.add(PalmFortuneBeats.together(seed, keys[0], keys[1]));
    }
    for (final value in seen) {
      if (value == opening) continue;
      parts.add(value);
    }
    final lifeThread = _life(lanes.keys.toSet(), themes);
    if (lifeThread.isNotEmpty) {
      parts.add(PalmFortuneBeats.you(seed, lifeThread));
    }
    if (marks.isNotEmpty) parts.add(PalmFortuneBeats.mark(seed, marks.first));
    final askLanes = _askLanes(lanes);
    if (askLanes.isNotEmpty && seed % 3 != 0) {
      parts.add(PalmFortuneBeats.ask(askLanes, seed));
    } else if (parts.length < 2) {
      parts.add(PalmFortuneBeats.close(seed));
    }
    return HumanReader.guard(FortuneVoice.joinSentences(parts, max: 8));
  }

  static Set<String> _askLanes(Map<String, String> lanes) => {
        for (final entry in lanes.entries)
          if (!PalmObservation.uncertain(entry.value)) entry.key,
      };

  static Map<String, String> _lanes({
    required String heart,
    required String head,
    required String life,
    required String fate,
  }) =>
      {
        if (heart.isNotEmpty) 'heart': heart,
        if (head.isNotEmpty) 'head': head,
        if (life.isNotEmpty) 'life': life,
        if (fate.isNotEmpty) 'fate': fate,
      };

  static String _life(Set<String> lanes, List<String> themes) {
    for (final theme in themes) {
      final resolved = DiscoveryTheme.resolve(theme);
      if (resolved == null) continue;
      final label = resolved.localized;
      if (label.isEmpty) continue;
      if ((resolved == DiscoveryTheme.love ||
              resolved == DiscoveryTheme.relationship) &&
          lanes.contains('heart')) {
        return label;
      }
      if ((resolved == DiscoveryTheme.decision ||
              resolved == DiscoveryTheme.indecision ||
              resolved == DiscoveryTheme.communication) &&
          lanes.contains('head')) {
        return label;
      }
      if ((resolved == DiscoveryTheme.change ||
              resolved == DiscoveryTheme.career ||
              resolved == DiscoveryTheme.redirection) &&
          (lanes.contains('fate') || lanes.contains('head'))) {
        return label;
      }
      if ((resolved == DiscoveryTheme.rest ||
              resolved == DiscoveryTheme.inward) &&
          lanes.contains('life')) {
        return label;
      }
    }
    return '';
  }
}
