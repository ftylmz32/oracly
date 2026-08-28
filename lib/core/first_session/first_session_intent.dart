/// RC-012 — One-shot intent to begin the first guided reading after onboarding.
library;

import '../data/datasources/local_storage.dart';

abstract final class FirstSessionIntent {
  FirstSessionIntent._();

  static const storageKey = 'first_session_pending_reading';

  static Future<void> requestFirstReading(LocalStorage storage) {
    return storage.setBool(storageKey, true);
  }

  static bool isPending(LocalStorage storage) =>
      storage.getBool(storageKey) == true;

  static Future<bool> consumePendingFirstReading(LocalStorage storage) async {
    if (!isPending(storage)) return false;
    await storage.setBool(storageKey, false);
    return true;
  }
}
