/// Typed errors for Narrative Evidence (Phase 3D.1A).
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
