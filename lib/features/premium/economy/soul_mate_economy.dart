/// SoulMate gem hook — membership is the gate; no invented gem price.
library;

abstract final class SoulMateEconomy {
  SoulMateEconomy._();

  static int? get drawCost => null;

  static const ledgerKey = 'soulmate_gem_charged';

  static bool get hasCost => drawCost != null && drawCost! > 0;
}
