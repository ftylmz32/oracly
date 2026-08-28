/// Canonical spread layout — count, slots, read order.
library;

import 'package:flutter/foundation.dart';

import 'tarot_spread.dart';
import 'tarot_spread_positions.dart';

@immutable
class TarotSpreadDefinition {
  const TarotSpreadDefinition({
    required this.type,
    required this.cardCount,
    required this.positions,
    required this.interpretationOrder,
  });

  final TarotSpreadType type;
  final int cardCount;
  final List<TarotPosition> positions;
  final List<int> interpretationOrder;

  bool get isConsistent {
    if (positions.length != cardCount) return false;
    if (interpretationOrder.length != cardCount) return false;
    if (interpretationOrder.toSet().length != cardCount) return false;
    return interpretationOrder.every((i) => i >= 0 && i < cardCount);
  }

  List<TarotPosition> get interpretationSequence => [
        for (final i in interpretationOrder) positions[i],
      ];
}
