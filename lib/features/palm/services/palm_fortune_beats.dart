/// Seeded palm-reading turns. Observation first; no textbook line cards.
library;

import '../../../core/l10n/l10n.dart';
import '../data/palm_observation.dart';

abstract final class PalmFortuneBeats {
  PalmFortuneBeats._();

  static String look(int seed, String seen) => _fill('palm.read.look.${seed % 5}', {
        'seen': PalmObservation.clip(seen),
      });

  static String together(int seed, String firstLane, String secondLane) {
    return _fill('palm.read.together.${seed % 5}', {
      'a': OraclyL10n.t('palm.read.line.$firstLane'),
      'b': OraclyL10n.t('palm.read.line.$secondLane'),
    });
  }

  static String meaning(String lane, String seen, int seed) {
    if (PalmObservation.uncertain(seen)) return seen;
    return _fill('palm.read.$lane.${seed % 3}', {
      'seen': PalmObservation.clip(seen),
    });
  }

  static String you(int seed, String life) {
    if (seed.abs() % 3 == 0) {
      return _fill('palm.read.you.theme', {
        'life': PalmObservation.clip(life),
      });
    }
    return _fill('palm.read.you.${seed % 3}', {
      'life': PalmObservation.clip(life),
    });
  }

  static String mark(int seed, String name) =>
      _fill('palm.read.mark.${seed % 3}', {
        'mark': PalmObservation.clip(name),
      });

  static String hedge() => OraclyL10n.t('palm.read.hedge');

  static String close(int seed) =>
      OraclyL10n.t('palm.read.close.${seed.abs() % 3}');

  static String ask(Set<String> lanes, int seed) {
    final key = _askKey(lanes);
    if (seed.abs() % 2 == 1) return OraclyL10n.t('$key.1');
    return OraclyL10n.t(key);
  }

  static String _askKey(Set<String> lanes) {
    if (lanes.contains('heart')) return 'palm.read.ask.heart';
    if (lanes.contains('head')) return 'palm.read.ask.head';
    if (lanes.contains('life')) return 'palm.read.ask.life';
    if (lanes.contains('fate')) return 'palm.read.ask.fate';
    return 'palm.read.ask.open';
  }

  static String _fill(String key, Map<String, String> vars) {
    var out = OraclyL10n.t(key);
    for (final entry in vars.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }
}
