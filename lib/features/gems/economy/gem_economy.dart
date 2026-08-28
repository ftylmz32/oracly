/// Canonical gem amounts — one economy, no invented IAP prices.
library;

abstract final class GemEconomy {
  GemEconomy._();

  static const int dailyReward = 50;
  static const int tarotReading = 20;

  /// Exactly one tarot reading. Granted once per device.
  static int get starterGrant => tarotReading;
}
