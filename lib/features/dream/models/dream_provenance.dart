/// Result-level truth about who wrote the sections a user is shown.
library;

enum DreamProvenance {
  /// Every shown interpretive section is accepted AI text.
  aiOnly,

  /// Shown sections combine accepted AI text and on-device text.
  mixed,

  /// Shown sections are on-device text only — no AI claim.
  localOnly,

  /// Saved before sections carried a source — neutral, no AI claim.
  legacyUnknown,
}
