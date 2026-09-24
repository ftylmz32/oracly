/// Phase 6E — Classical dual-run shadow status contracts (QA only).
library;

/// Outcome of a Classical Narrative dual-run shadow evaluation.
enum NarrativeTarotShadowStatus {
  pass,
  notLiveLaunchCandidate,
  invalidSession,
  safetyBlocked,
  phase5ShadowFailed,
  phase3Unavailable,
  historyUnavailable,
  parityMismatch,
  serializationFailed,
}

/// Explicit invalid-session / input-firewall reasons.
enum NarrativeTarotShadowInputFailure {
  emptySessionId,
  emptyReadingId,
  emptyDrawnCards,
  cardCountMismatch,
  invalidRitualCard,
  duplicatePosition,
  outOfRangePosition,
  missingPosition,
  positionKeyMismatch,
}

/// Offline structured-result assessor stage outcome.
enum NarrativeTarotShadowAssessStatus {
  pass,
  parseFailure,
  narrativeEvidenceFailure,
  aiOutputQualityFailure,
}
