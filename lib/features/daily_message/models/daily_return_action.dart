/// Suggested next step — always a free discovery action.
library;

enum DailyReturnAction {
  exploreTheme,
  drawCard,
  tellDream,
  talkToOr,
  readPalm,
  readCoffee,
  askTarot,
  readAstrology,
  exploreStarMap;

  bool get isFree => true;

  static DailyReturnAction fromName(String? raw) {
    return DailyReturnAction.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => DailyReturnAction.talkToOr,
    );
  }
}
