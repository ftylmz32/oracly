/// Spread definitions — count, slots, interpretation order.
library;

import 'tarot_spread.dart';
import 'tarot_spread_definition.dart';
import 'tarot_spread_positions.dart';

const kSingleSpread = TarotSpreadDefinition(
  type: TarotSpreadType.single,
  cardCount: 1,
  positions: kSinglePositions,
  interpretationOrder: [0],
);

const kThreeCardSpread = TarotSpreadDefinition(
  type: TarotSpreadType.threeCard,
  cardCount: 3,
  positions: kThreeCardPositions,
  interpretationOrder: [0, 1, 2],
);

const kFiveCardSpread = TarotSpreadDefinition(
  type: TarotSpreadType.fiveCard,
  cardCount: 5,
  positions: kFiveCardPositions,
  interpretationOrder: [0, 1, 2, 3, 4],
);

const kSevenCardSpread = TarotSpreadDefinition(
  type: TarotSpreadType.sevenCard,
  cardCount: 7,
  positions: kSevenCardPositions,
  interpretationOrder: [0, 1, 2, 3, 4, 5, 6],
);

const kCelticCrossSpread = TarotSpreadDefinition(
  type: TarotSpreadType.celticCross,
  cardCount: 10,
  positions: kCelticCrossPositions,
  interpretationOrder: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
);
