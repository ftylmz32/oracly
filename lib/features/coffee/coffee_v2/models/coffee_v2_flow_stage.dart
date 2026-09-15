/// UI stages the Coffee V2 guided-capture flow can be in. Purely a
/// presentation concern — never persisted; always re-derived from
/// `CoffeeV2SubmissionController.record` plus a small amount of ephemeral
/// UI-only state (preview candidate, intro-dismissed, replacing slot).
library;

enum CoffeeV2FlowStage {
  /// Awaiting the first `recoverDraftOrSubmission()` to resolve.
  booting,

  /// No `ReadingFeatureRunner`/staged-image gateway available — fails
  /// closed exactly like the legacy controller does without a live runner.
  unavailable,

  intro,
  step,
  preview,
  finalReview,

  /// `beginSubmission`/`retrySubmission` in flight, or awaiting a retry
  /// tap after a retryable staging failure.
  activeStaging,

  /// All three slots staged; observing the resulting `ReadingOperation`
  /// via the existing server-owned wait/live/result machinery.
  activeObserving,
}

enum CoffeeV2ConfirmOutcome {
  /// Candidate committed; flow should advance to the next incomplete slot.
  committedAdvance,

  /// Candidate committed while replacing from Final Review; flow should
  /// return to Final Review.
  committedReturnToReview,

  /// setSlot rejected the candidate (invalid/oversize/unsupported).
  invalidPhoto,

  /// Candidate was an exact duplicate of an already-confirmed slot.
  duplicate,

  /// No candidate/slot was pending — nothing to confirm.
  none,
}
