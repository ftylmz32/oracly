/// Score breakdown, pair evaluation, and ranked candidate (3D.1C).
library;

import 'narrative_keyword_contrasts.dart';
import 'narrative_relationship_context.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_spread_semantics.dart';
import '../domain/reversed_transform_kind.dart';

class NarrativeRelationshipScoreBreakdown {
  const NarrativeRelationshipScoreBreakdown({
    required this.overlap,
    required this.contrast,
    required this.transform,
    required this.canonical,
    required this.position,
    required this.question,
    required this.total,
  });

  final double overlap;
  final double contrast;
  final double transform;
  final double canonical;
  final double position;
  final double question;
  final double total;
}

class NarrativePairEvaluation {
  const NarrativePairEvaluation({
    required this.left,
    required this.right,
    required this.breakdown,
    required this.sharedSemanticIds,
    required this.sharedKeywordIds,
    required this.sharedTagOnlyIds,
    required this.contrastClass,
    required this.effectiveSharedTransforms,
    required this.canonicalRelated,
    required this.positionEdgeKind,
    required this.questionRelevant,
    required this.independentFamilyCount,
    required this.standardPath,
    required this.canonicalPath,
    required this.positionStrongPath,
    required this.normalAdmitted,
    required this.pageSuitGuard,
    required this.courtRankGuard,
    required this.themePairEligible,
    required this.higherPriorityKind,
    required this.provenanceTokens,
    required this.strength,
  });

  final NarrativeRelationshipCardContext left;
  final NarrativeRelationshipCardContext right;
  final NarrativeRelationshipScoreBreakdown breakdown;
  final List<String> sharedSemanticIds;
  final List<String> sharedKeywordIds;
  final List<String> sharedTagOnlyIds;
  final NarrativeKeywordContrastClass? contrastClass;
  final List<ReversedTransformKind> effectiveSharedTransforms;
  final bool canonicalRelated;
  final PositionEdgeKind? positionEdgeKind;
  final bool questionRelevant;
  final int independentFamilyCount;
  final bool standardPath;
  final bool canonicalPath;
  final bool positionStrongPath;
  final bool normalAdmitted;
  final bool pageSuitGuard;
  final bool courtRankGuard;
  final bool themePairEligible;
  final RelationshipKind? higherPriorityKind;
  final List<String> provenanceTokens;
  final double strength;
}

class NarrativeRelationshipCandidate {
  const NarrativeRelationshipCandidate({
    required this.leftCanonicalId,
    required this.rightCanonicalId,
    required this.leftPositionKey,
    required this.rightPositionKey,
    required this.leftPositionIndex,
    required this.rightPositionIndex,
    required this.kind,
    required this.strength,
    required this.totalScore,
    required this.provenanceTokens,
    required this.pageSuitGuard,
    required this.courtRankGuard,
    required this.sharedSemanticIds,
  });

  final String leftCanonicalId;
  final String rightCanonicalId;
  final String leftPositionKey;
  final String rightPositionKey;
  final int leftPositionIndex;
  final int rightPositionIndex;
  final RelationshipKind kind;
  final double strength;
  final double totalScore;
  final List<String> provenanceTokens;
  final bool pageSuitGuard;
  final bool courtRankGuard;
  final List<String> sharedSemanticIds;
}
