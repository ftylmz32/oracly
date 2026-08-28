/// Palm gem hook — no price invented until the gem system defines one.
library;

abstract final class PalmEconomy {
  PalmEconomy._();

  static int? get analysisCost => null;

  static const ledgerKey = 'palm_gem_charged';

  static bool get hasCost => analysisCost != null && analysisCost! > 0;
}
