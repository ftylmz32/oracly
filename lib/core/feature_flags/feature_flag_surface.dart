/// Emergency kill-switch surfaces with a known stable fallback.
library;

enum FeatureFlagSurface {
  tarotAnimation,
  orVoice,
  coffeeResult,
  astrologyVisual,
  dailyMessage,

  /// Starting a NEW Coffee V3 four-view capture; stable = Coffee V2.
  coffeeV3Capture,
}
