/// Closed-universe relationship assertions for NarrativeEvidenceBuilder.
library;

import 'narrative_card_evidence.dart';
import 'narrative_evidence_error.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_request.dart';
import 'narrative_spread_semantics.dart';

abstract final class NarrativeEvidenceClosedUniverse {
  NarrativeEvidenceClosedUniverse._();

  static void assertRelationships({
    required List<TarotNarrativeCardEvidence> cards,
    required List<TarotNarrativeRelationshipEvidence> relationships,
    required SpreadSemanticDefinition spread,
  }) {
    final cardIds = cards.map((c) => c.canonicalCardId).toSet();
    final positionKeys = spread.positions.map((p) => p.positionKey).toSet();
    final evidenceIds = <String>{};

    if (relationships.length > RequestBounds.defaults.maxRelationships) {
      throw NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.spreadMismatch,
        message: 'relationship count ${relationships.length}',
      );
    }

    for (final rel in relationships) {
      if (rel.evidenceId.isEmpty || !evidenceIds.add(rel.evidenceId)) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.duplicateEvidenceId,
          message: rel.evidenceId,
        );
      }
      if (!cardIds.contains(rel.leftCardId) ||
          !cardIds.contains(rel.rightCardId) ||
          !positionKeys.contains(rel.leftPositionKey) ||
          !positionKeys.contains(rel.rightPositionKey)) {
        throw const NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.spreadMismatch,
          message: 'relationship outside closed universe',
        );
      }
    }
  }
}
