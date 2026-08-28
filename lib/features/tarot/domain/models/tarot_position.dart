/// OR-1170 — Spread position lookup.
library;

export 'spread_engine.dart' show SpreadEngine;
export 'tarot_spread_positions.dart' show TarotPosition;

import 'spread_engine.dart';
import 'tarot_spread.dart';
import 'tarot_spread_positions.dart';

abstract final class SpreadService {
  SpreadService._();

  static List<TarotPosition> positionsFor(TarotSpreadType spread) =>
      SpreadEngine.positionsFor(spread);

  static TarotPosition? positionAt(TarotSpreadType spread, int index) =>
      SpreadEngine.positionAt(spread, index);
}
