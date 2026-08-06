/// OR-1140 — Tarot spread position layout calculator.
library;

import '../core/oracle_engine_type.dart';

class SpreadPosition {
  const SpreadPosition({
    required this.index,
    required this.labelKey,
  });

  final int index;
  final String labelKey;
}

abstract class TarotSpreadCalculator {
  List<SpreadPosition> positionsFor(TarotSpreadType spread);
  int requiredCardCount(TarotSpreadType spread);
}

class ConfigurableTarotSpreadCalculator implements TarotSpreadCalculator {
  static const _layouts = {
    TarotSpreadType.singleCard: ['tarot.pos.present'],
    TarotSpreadType.threeCards: [
      'tarot.pos.past',
      'tarot.pos.present',
      'tarot.pos.future',
    ],
    TarotSpreadType.fiveCards: [
      'tarot.pos.situation',
      'tarot.pos.challenge',
      'tarot.pos.advice',
      'tarot.pos.near',
      'tarot.pos.outcome',
    ],
    TarotSpreadType.celticCross: [
      'tarot.pos.present',
      'tarot.pos.challenge',
      'tarot.pos.past',
      'tarot.pos.future',
      'tarot.pos.above',
      'tarot.pos.below',
      'tarot.pos.advice',
      'tarot.pos.external',
      'tarot.pos.hopes',
      'tarot.pos.outcome',
    ],
    TarotSpreadType.relationship: [
      'tarot.pos.self',
      'tarot.pos.other',
      'tarot.pos.dynamic',
      'tarot.pos.strength',
      'tarot.pos.growth',
    ],
    TarotSpreadType.career: [
      'tarot.pos.current',
      'tarot.pos.block',
      'tarot.pos.action',
      'tarot.pos.opportunity',
      'tarot.pos.outcome',
    ],
    TarotSpreadType.decision: [
      'tarot.pos.option_a',
      'tarot.pos.option_b',
      'tarot.pos.hidden',
      'tarot.pos.advice',
    ],
    TarotSpreadType.future: [
      'tarot.pos.near',
      'tarot.pos.mid',
      'tarot.pos.far',
    ],
  };

  @override
  List<SpreadPosition> positionsFor(TarotSpreadType spread) {
    final labels = _layouts[spread] ?? _layouts[TarotSpreadType.singleCard]!;
    return [
      for (var i = 0; i < labels.length; i++)
        SpreadPosition(index: i, labelKey: labels[i]),
    ];
  }

  @override
  int requiredCardCount(TarotSpreadType spread) =>
      positionsFor(spread).length;
}
