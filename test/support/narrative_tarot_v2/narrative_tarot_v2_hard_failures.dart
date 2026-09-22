/// Phase 2 offline CONTRACT HARNESS — hard-failure taxonomy.
///
/// NOT production NarrativeQualityValidator.
library;

abstract final class Ntv2HardFailure {
  static const unknownCardRef = 'unknown_card_ref';
  static const undrawnCardRef = 'undrawn_card_ref';
  static const unknownPositionRef = 'unknown_position_ref';
  static const unknownRelationshipEvidence = 'unknown_relationship_evidence';
  static const unknownMemoryEvidence = 'unknown_memory_evidence';
  static const unknownRecurrenceEvidence = 'unknown_recurrence_evidence';
  static const recurrenceCountMismatch = 'recurrence_count_mismatch';
  static const fabricatedRecurrence = 'fabricated_recurrence';
  static const orientationMismatch = 'orientation_mismatch';
  static const spreadFactMismatch = 'spread_fact_mismatch';
  static const unsupportedCertainty = 'unsupported_certainty';
  static const safetyViolation = 'safety_violation';
  static const languageMismatch = 'language_mismatch';
  static const foreignAccountEvidence = 'foreign_account_evidence';
  static const deletedEvidenceUsed = 'deleted_evidence_used';

  static const all = <String>{
    unknownCardRef,
    undrawnCardRef,
    unknownPositionRef,
    unknownRelationshipEvidence,
    unknownMemoryEvidence,
    unknownRecurrenceEvidence,
    recurrenceCountMismatch,
    fabricatedRecurrence,
    orientationMismatch,
    spreadFactMismatch,
    unsupportedCertainty,
    safetyViolation,
    languageMismatch,
    foreignAccountEvidence,
    deletedEvidenceUsed,
  };

  static const referential = <String>{
    unknownCardRef,
    undrawnCardRef,
    unknownPositionRef,
    unknownRelationshipEvidence,
    unknownMemoryEvidence,
    unknownRecurrenceEvidence,
    orientationMismatch,
    foreignAccountEvidence,
    deletedEvidenceUsed,
    recurrenceCountMismatch,
  };
}
