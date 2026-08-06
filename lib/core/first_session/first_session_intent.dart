/// RC-012 — One-shot intent to begin the first guided reading after onboarding.
library;

abstract final class FirstSessionIntent {
  FirstSessionIntent._();

  static bool _pending = false;

  static void requestFirstReading() => _pending = true;

  static bool consumePendingFirstReading() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }
}
