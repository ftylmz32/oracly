/// Spread engine — real layouts bound to actual draws.
library;

import 'reading_session.dart';
import 'tarot_spread.dart';
import 'tarot_spread_catalog.dart';
import 'tarot_spread_definition.dart';
import 'tarot_spread_positions.dart';

abstract final class SpreadEngine {
  SpreadEngine._();

  static TarotSpreadDefinition of(TarotSpreadType type) {
    return switch (type) {
      TarotSpreadType.single => kSingleSpread,
      TarotSpreadType.threeCard => kThreeCardSpread,
      TarotSpreadType.fiveCard => kFiveCardSpread,
      TarotSpreadType.sevenCard => kSevenCardSpread,
      TarotSpreadType.celticCross => kCelticCrossSpread,
    };
  }

  static List<TarotPosition> positionsFor(TarotSpreadType type) =>
      of(type).positions;

  static TarotPosition? positionAt(TarotSpreadType type, int index) {
    final list = positionsFor(type);
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }

  /// Drawn pile cards only — never padded. Order follows the spread.
  static List<TarotDrawnCard> interpretationCards({
    required TarotSpreadType spread,
    required List<TarotDrawnCard> drawn,
  }) {
    final byIndex = <int, TarotDrawnCard>{
      for (final card in drawn) card.positionIndex: card,
    };
    return [
      for (final i in of(spread).interpretationOrder)
        if (byIndex[i] != null) byIndex[i]!,
    ];
  }
}
