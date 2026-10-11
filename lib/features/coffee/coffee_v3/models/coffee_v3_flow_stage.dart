/// UI stages of the Coffee V3 three-photo flow. Presentation only — never
/// persisted; re-derived from the V3 submission record plus ephemeral UI
/// state.
library;

enum CoffeeV3FlowStage {
  booting,

  /// No live reading transport / staged-image gateway.
  unavailable,

  intro,
  step,
  preview,
  finalReview,
  activeStaging,
  activeObserving,

  /// Nothing V3-owned exists (no photos, no operation) and creating a NEW
  /// V3 reading is not allowed right now — hand back to the default route.
  exitToDefault,
}

enum CoffeeV3ConfirmOutcome {
  committedAdvance,
  committedReturnToReview,
  invalidPhoto,
  duplicate,
  none,
}
