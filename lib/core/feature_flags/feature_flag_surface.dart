/// Emergency kill-switch surfaces with a known stable fallback.
library;

enum FeatureFlagSurface {
  tarotAnimation,
  orVoice,
  coffeeResult,
  astrologyVisual,
  dailyMessage,

  /// Starting a NEW Coffee V3 three-photo capture; stable = Coffee V2.
  coffeeV3Capture,

  /// Freemium V1 client experience; stable = the existing entry flows.
  freemiumV1,

  /// Ad SDK + consent gate; stable = no SDK start, no ad request.
  adsV1,
}
