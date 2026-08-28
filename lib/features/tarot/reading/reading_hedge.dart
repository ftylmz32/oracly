/// Uncertainty — observation, never a promised future.
library;

import '../copy/tarot_l10n.dart';

abstract final class ReadingHedge {
  ReadingHedge._();

  static const _keys = [
    'tarot.read.hedge.0',
    'tarot.read.hedge.1',
    'tarot.read.hedge.2',
    'tarot.read.hedge.3',
    'tarot.read.hedge.4',
  ];

  static List<String> get phrases =>
      [for (final key in _keys) TarotL10n.fill(key)];

  static String of(int seed) => phrases[seed.abs() % phrases.length];
}
