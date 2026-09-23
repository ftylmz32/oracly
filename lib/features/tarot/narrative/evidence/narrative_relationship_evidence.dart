/// Relationship evidence model + kind enum (Phase 3D.1A — no scoring).
library;

/// Deterministic relationship classification for later Evidence Engine scoring.
enum RelationshipKind {
  support,
  reinforcement,
  contrast,
  conflict,
  causeEffect,
  blockage,
  resolution,
  escalation,
  softening,

  /// Current-spread theme echo ONLY. Never historical recurrence.
  themeRepetition,
}

class TarotNarrativeRelationshipEvidence {
  const TarotNarrativeRelationshipEvidence({
    required this.evidenceId,
    required this.leftCardId,
    required this.rightCardId,
    required this.leftPositionKey,
    required this.rightPositionKey,
    required this.kind,
    required this.provenance,
    required this.strength,
    this.noteKeyOrText,
  });

  final String evidenceId;
  final String leftCardId;
  final String rightCardId;
  final String leftPositionKey;
  final String rightPositionKey;
  final RelationshipKind kind;
  final String provenance;
  final double strength;
  final String? noteKeyOrText;
}
