/// Kind resolution + support/reinforcement fallback (3D.1C).
library;

import 'narrative_keyword_contrasts.dart';
import 'narrative_keyword_discrimination.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_relationship_rules.dart';
import 'narrative_spread_semantics.dart';
import '../domain/reversed_transform_kind.dart';

abstract final class NarrativeRelationshipKindResolver {
  NarrativeRelationshipKindResolver._();

  static RelationshipKind? higherPriority({
    required NarrativeKeywordContrastClass? contrastClass,
    required PositionEdgeKind? edgeKind,
    required bool directed,
    required PositionRole leftRole,
    required PositionRole rightRole,
    required Set<String> sharedSemantic,
    required List<ReversedTransformKind> effectiveTransforms,
    required bool hasSemantic,
    required int independentFamilyCount,
  }) {
    final contrastCondition =
        contrastClass == NarrativeKeywordContrastClass.hard ||
        (contrastClass == NarrativeKeywordContrastClass.contextual &&
            edgeKind == PositionEdgeKind.opposition);
    if (contrastCondition) {
      return _conflictOrContrast(
        contrastClass: contrastClass!,
        edgeKind: edgeKind,
        leftRole: leftRole,
        rightRole: rightRole,
      );
    }

    if (edgeKind == PositionEdgeKind.temporal && directed && hasSemantic) {
      return RelationshipKind.causeEffect;
    }

    final hasBlockageKw = sharedSemantic.any(
      NarrativeRelationshipRules.blockageKeywords.contains,
    );
    final hasBlockageTf = effectiveTransforms.any(
      NarrativeRelationshipRules.blockageTransforms.contains,
    );
    if ((hasBlockageKw || hasBlockageTf) && independentFamilyCount >= 2) {
      return RelationshipKind.blockage;
    }

    final hasSoft = sharedSemantic.any(
      NarrativeRelationshipRules.softeningKeywords.contains,
    );
    if (hasSoft &&
        (edgeKind == PositionEdgeKind.supportive ||
            edgeKind == PositionEdgeKind.pressure ||
            contrastClass != null)) {
      return RelationshipKind.softening;
    }

    final hasEscKw = sharedSemantic.any(
      NarrativeRelationshipRules.escalationKeywords.contains,
    );
    final hasEscTf = effectiveTransforms.any(
      NarrativeRelationshipRules.escalationTransforms.contains,
    );
    if ((hasEscKw || hasEscTf) && independentFamilyCount >= 2) {
      return RelationshipKind.escalation;
    }

    final hasRes = sharedSemantic.any(
      NarrativeRelationshipRules.resolutionKeywords.contains,
    );
    if (hasRes && edgeKind == PositionEdgeKind.supportive) {
      return RelationshipKind.resolution;
    }

    return null;
  }

  static RelationshipKind supportOrReinforcement(Set<String> sharedSemantic) {
    final specific = sharedSemantic
        .where((id) => NarrativeKeywordDiscrimination.df(id) < 8)
        .toList();
    if (specific.length >= 2) {
      final mean =
          specific
              .map(NarrativeKeywordDiscrimination.weight)
              .reduce((a, b) => a + b) /
          specific.length;
      if (mean >= NarrativeRelationshipRules.reinforcementMeanRawMin) {
        return RelationshipKind.reinforcement;
      }
    }
    return RelationshipKind.support;
  }

  static RelationshipKind _conflictOrContrast({
    required NarrativeKeywordContrastClass contrastClass,
    required PositionEdgeKind? edgeKind,
    required PositionRole leftRole,
    required PositionRole rightRole,
  }) {
    final challengeRoles = {PositionRole.challenge, PositionRole.avoid};
    final oppositionToChallenge =
        edgeKind == PositionEdgeKind.opposition &&
        (challengeRoles.contains(leftRole) ||
            challengeRoles.contains(rightRole));
    final hardPressure =
        contrastClass == NarrativeKeywordContrastClass.hard &&
        edgeKind == PositionEdgeKind.pressure;
    if (oppositionToChallenge || hardPressure) return RelationshipKind.conflict;
    return RelationshipKind.contrast;
  }
}
