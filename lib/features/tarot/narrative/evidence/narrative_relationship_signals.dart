/// Shared-id + score component assembly (3D.1C helper).
library;

import 'narrative_keyword_discrimination.dart';
import 'narrative_question_grounding.dart';
import 'narrative_relationship_context.dart';
import 'narrative_relationship_guards.dart';
import 'narrative_relationship_rules.dart';
import 'narrative_transform_signals.dart';
import '../domain/reversed_transform_kind.dart';
import 'narrative_keyword_contrasts.dart';

class NarrativeRelationshipSignalBundle {
  const NarrativeRelationshipSignalBundle({
    required this.sharedSemantic,
    required this.sharedKeywords,
    required this.sharedTagOnly,
    required this.pageGuard,
    required this.courtGuard,
    required this.overlap,
    required this.contrastClass,
    required this.contrast,
    required this.effective,
    required this.transformScore,
    required this.canonical,
    required this.canonicalScore,
    required this.positionScore,
    required this.question,
    required this.total,
    required this.strength,
  });

  final List<String> sharedSemantic;
  final List<String> sharedKeywords;
  final List<String> sharedTagOnly;
  final bool pageGuard;
  final bool courtGuard;
  final double overlap;
  final NarrativeKeywordContrastClass? contrastClass;
  final double contrast;
  final List<ReversedTransformKind> effective;
  final double transformScore;
  final bool canonical;
  final double canonicalScore;
  final double positionScore;
  final double question;
  final double total;
  final double strength;

  factory NarrativeRelationshipSignalBundle.compute({
    required NarrativeRelationshipCardContext left,
    required NarrativeRelationshipCardContext right,
    required NarrativePositionPairMatch pos,
    required QuestionKind questionKind,
  }) {
    final sharedSemantic =
        left.semanticChannel.semanticIds
            .toSet()
            .intersection(right.semanticChannel.semanticIds.toSet())
            .toList()
          ..sort();
    final sharedKeywords =
        left.keywordIds.toSet().intersection(right.keywordIds.toSet()).toList()
          ..sort();
    final sharedTagOnly =
        left.semanticChannel.tagOnlyIds
            .toSet()
            .intersection(right.semanticChannel.tagOnlyIds.toSet())
            .toList()
          ..sort();

    final pageGuard = NarrativeRelationshipGuards.pageSuitGuard(left, right);
    final courtGuard = NarrativeRelationshipGuards.courtRankGuard(left, right);

    var overlap = 0.0;
    for (final id in sharedSemantic) {
      overlap += NarrativeKeywordDiscrimination.weight(id) / 6.0;
    }
    if (pageGuard || courtGuard) {
      if (overlap > NarrativeRelationshipRules.frOverlapCap) {
        overlap = NarrativeRelationshipRules.frOverlapCap;
      }
    }

    final contrastClass = NarrativeRelationshipGuards.maxContrast(left, right);
    final contrast = NarrativeRelationshipRules.contrastScore(contrastClass);
    final transforms = NarrativeTransformPairSignals.from(
      leftTransforms: left.transforms,
      rightTransforms: right.transforms,
      leftSemanticIds: left.semanticChannel.semanticIds,
      rightSemanticIds: right.semanticChannel.semanticIds,
    );
    final effective = transforms.effectiveSharedTransforms;
    var transformScore =
        NarrativeRelationshipRules.transformEach * effective.length;
    if (transformScore > NarrativeRelationshipRules.transformCap) {
      transformScore = NarrativeRelationshipRules.transformCap;
    }

    final canonical =
        left.relatedIds.contains(right.canonicalCardId) ||
        right.relatedIds.contains(left.canonicalCardId);
    final canonicalScore = canonical
        ? NarrativeRelationshipRules.canonicalBonus
        : 0.0;
    final positionScore = pos.edgeKind == null
        ? 0.0
        : (NarrativeRelationshipRules.positionBonus[pos.edgeKind!] ?? 0.0);
    final question = NarrativeRelationshipRules.questionScore(
      questionKind,
      sharedSemantic.toSet(),
    );
    final total = NarrativeRelationshipRules.clampTotal(
      overlap +
          contrast +
          transformScore +
          canonicalScore +
          positionScore +
          question,
    );
    var strength = total / NarrativeRelationshipRules.scoreClampMax;
    if ((pageGuard || courtGuard) &&
        strength > NarrativeRelationshipRules.frStrengthCap) {
      strength = NarrativeRelationshipRules.frStrengthCap;
    }

    return NarrativeRelationshipSignalBundle(
      sharedSemantic: sharedSemantic,
      sharedKeywords: sharedKeywords,
      sharedTagOnly: sharedTagOnly,
      pageGuard: pageGuard,
      courtGuard: courtGuard,
      overlap: overlap,
      contrastClass: contrastClass,
      contrast: contrast,
      effective: effective,
      transformScore: transformScore,
      canonical: canonical,
      canonicalScore: canonicalScore,
      positionScore: positionScore,
      question: question,
      total: total,
      strength: strength,
    );
  }
}
