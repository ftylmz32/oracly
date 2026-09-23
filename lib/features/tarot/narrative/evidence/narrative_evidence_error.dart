/// Typed errors for Narrative Evidence (Phase 3D.1A / 3D.1D).
library;

enum NarrativeEvidenceErrorCode {
  unknownCanonicalCardId,
  profileMissing,
  duplicatePositionKey,
  cardCountMismatch,
  unknownPositionKey,
  invalidOrientation,
  spreadMismatch,
  invalidOntologyId,
  duplicateEvidenceId,

  /// Same physical canonical card appears twice in one reading.
  duplicateCardId,

  /// Ritual id invalid or resolves to a different canonical card.
  ritualCardMismatch,
}

class NarrativeEvidenceException implements Exception {
  const NarrativeEvidenceException(this.code, {this.message});

  final NarrativeEvidenceErrorCode code;

  /// Safe diagnostic only — never include private question text.
  final String? message;

  @override
  String toString() => message == null
      ? 'NarrativeEvidenceException($code)'
      : 'NarrativeEvidenceException($code: $message)';
}
