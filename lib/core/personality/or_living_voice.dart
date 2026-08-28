/// Living OR chrome — same core, contextual variation, no template loop.
library;

import '../l10n/l10n.dart';
import 'or_living_surface.dart';
import 'or_phrase_rotator.dart';

export 'or_living_surface.dart';

abstract final class OrLivingVoice {
  OrLivingVoice._();

  static String promptRule() => OraclyL10n.t('or.live.prompt');

  static String greeting({
    required String personality,
    bool again = false,
    DateTime? moment,
  }) {
    final stem = again ? 'or.hi2.$personality' : 'or.hi.$personality';
    return OrPhraseRotator.daily(
      pool: _keyed(stem, 2),
      day: moment ?? DateTime.now(),
      salt: stem,
    );
  }

  static String thinking({
    OrLivingSurface surface = OrLivingSurface.or,
    DateTime? moment,
  }) {
    return OrPhraseRotator.session(
      pool: thinkingPool(surface),
      moment: moment ?? DateTime.now(),
      salt: 'think_${surface.name}',
    );
  }

  static String aside({DateTime? moment}) {
    return OrPhraseRotator.session(
      pool: asidePool(),
      moment: moment ?? DateTime.now(),
      salt: 'aside',
    );
  }

  static String closing({DateTime? moment}) {
    return OrPhraseRotator.session(
      pool: closingPool(),
      moment: moment ?? DateTime.now(),
      salt: 'outro',
    );
  }

  static String observePrefix({DateTime? moment}) {
    return OrPhraseRotator.session(
      pool: _keyed('or.live.prefix', 2),
      moment: moment ?? DateTime.now(),
      salt: 'prefix',
    );
  }

  static String fromStem(
    String stem, {
    int extras = 2,
    DateTime? moment,
    String salt = '',
  }) {
    return OrPhraseRotator.session(
      pool: _keyed(stem, extras),
      moment: moment ?? DateTime.now(),
      salt: salt.isEmpty ? stem : salt,
    );
  }

  static List<String> thinkingPool(OrLivingSurface surface) {
    return switch (surface) {
      OrLivingSurface.or => _keyed('or.thinking', 3),
      OrLivingSurface.tarot => _keyed('tarot.interpreting', 2),
      OrLivingSurface.coffee => _keyed('coffee.analyzing', 2),
      OrLivingSurface.palm => _keyed('palm.analyzing', 2),
      OrLivingSurface.dream => _keyed('dream.organizing', 2),
      OrLivingSurface.astrology => _keyed('astro.live', 2),
      OrLivingSurface.starMap => _keyed('star.live', 2),
    };
  }

  static List<String> asidePool() => [
        for (var i = 0; i < 4; i++) OraclyL10n.t('or.aside.$i'),
      ];

  static List<String> closingPool() => [
        for (var i = 0; i < 4; i++) OraclyL10n.t('or.outro.$i'),
      ];

  static List<String> _keyed(String stem, int extras) => [
        OraclyL10n.t(stem),
        for (var i = 1; i <= extras; i++) OraclyL10n.t('$stem.$i'),
      ];
}
