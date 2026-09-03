/// OR chamber session states — one surface language for access + reachability.
library;

/// Primary OR session surface. Chamber stays open in every value.
enum OrSessionState {
  /// Presence + preview + paywall; no live send.
  free,

  /// Healthy live path — network recovery success.
  success,

  /// Network reachability failed; composer stays for retry.
  offline,

  /// Soft recovery after offline / bootstrap — not a wall.
  reconnecting,

  /// A real retry is in flight — no fake reply, no stuck spinner.
  retrying,

  /// AI path not ready / provider error; retry stays available.
  providerUnavailable,

  /// Temporary throttle; wait and retry — no dead end.
  rateLimited,

  /// Auth/session rejected by proxy; sign-in again, chamber stays.
  sessionExpired,

  /// Store purchase or restore in flight.
  purchasePending,

  /// TTS/voice output unavailable; text chat remains.
  voiceUnavailable,

  /// Valid reply is visible; only local save failed — retry saves, not provider.
  saveFailed,
}
