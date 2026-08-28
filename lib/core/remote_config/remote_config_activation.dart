/// When a validated snapshot may become live.
library;

enum RemoteConfigActivation {
  /// Stage only — apply on the next session boundary.
  nextSession,

  /// Safe boundary (splash / controlled refresh) — activate now.
  sessionBoundary,

  /// Explicit product-controlled apply of staged config.
  controlled,
}
