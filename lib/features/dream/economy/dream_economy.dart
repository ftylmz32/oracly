/// Dream gem hook — no price invented until the gem system defines one.
library;

abstract final class DreamEconomy {
  DreamEconomy._();

  /// Analysis cost in gems. `null` means no cost is configured yet.
  static int? get analysisCost => null;

  static const ledgerKey = 'dream_gem_charged';

  static bool get hasCost => analysisCost != null && analysisCost! > 0;
}
