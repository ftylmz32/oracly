/// Tarot gem hook — one-card is free; deeper spreads use the gem economy.
library;

import '../../gems/economy/gem_economy.dart';
import '../domain/models/tarot_spread.dart';

abstract final class TarotEconomy {
  TarotEconomy._();

  /// Listed gem price for a paid spread. One-card is free.
  static int get readingCost => GemEconomy.tarotReading;

  static int? costFor(TarotSpreadType spread) {
    if (spread.cardCount <= 1) return null;
    return readingCost;
  }

  static bool isFree(TarotSpreadType spread) => costFor(spread) == null;

  static bool get hasCost => readingCost > 0;

  /// Membership is not required. Purchase is not configured.
  static bool requiresPremium(TarotSpreadType spread) => false;
}
