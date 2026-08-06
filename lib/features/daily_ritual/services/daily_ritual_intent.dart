/// EPIC-011 — Cross-tab intent for daily card draw (no gamification).
library;

/// Holds a one-shot request to begin today's single-card ritual on the tarot tab.
abstract final class DailyRitualIntent {
  DailyRitualIntent._();

  static bool _pendingDraw = false;

  static void requestDailyCardDraw() => _pendingDraw = true;

  /// Returns true once when a pending draw was waiting.
  static bool consumePendingDraw() {
    if (!_pendingDraw) return false;
    _pendingDraw = false;
    return true;
  }
}
