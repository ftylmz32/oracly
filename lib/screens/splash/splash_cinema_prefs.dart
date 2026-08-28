/// Persists splash seen state (legacy key retained for upgrades).
library;

import '../../core/data/datasources/local_storage.dart';

abstract final class SplashCinemaPrefs {
  SplashCinemaPrefs._();

  static const seenKey = 'splash_cinema_seen_v5';

  static Future<void> markSeen(LocalStorage storage) async {
    await storage.setBool(seenKey, true);
  }
}
