/// Phase 5E — typed shadow / Phase 3 / Phase 4 status contracts.
library;

/// Outcome of attempting frozen Phase 3 NarrativeEvidenceBuilder.
enum SignaturePhase3EvidenceStatus {
  builtClassical,
  blockedUnsupportedSignatureSpread,
  invalidInput,
}

/// Outcome of attempting frozen Phase 4 request enrichment.
enum SignaturePhase4HistoryStatus {
  notRequested,
  enrichedClassical,
  privacyBlocked,
  blockedUnsupportedSignatureSpread,
}

/// Typed shadow validation / evaluation failure.
enum SignatureShadowFailureCode {
  emptySessionId,
  emptyReadingId,
  unsupportedRuntimeSpread,
  cardCountMismatch,
  duplicatePositionIndex,
  missingPositionIndex,
  negativePositionIndex,
  outOfRangePositionIndex,
  positionKeyMismatch,
  invalidRitualCardId,
  unsupportedQuestionKind,
  missingNowForHistory,
  evidenceBuildFailed,
}

/// Whether Phase 5 Signature edges reach the frozen Phase 3 scorer.
enum SignaturePhase3EdgeConsumption {
  /// Classical launch spreads use frozen global edges only.
  classicalFrozenGlobal,

  /// Signature edges exist but are not consumed by Phase 3 scorer.
  signatureEdgesNotConsumed,
}
