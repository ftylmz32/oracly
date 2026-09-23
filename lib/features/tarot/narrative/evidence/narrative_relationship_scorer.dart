/// Deterministic pair scorer for prepared card contexts (3D.1C).
library;

import 'narrative_keyword_discrimination.dart';
import 'narrative_question_grounding.dart';
import 'narrative_relationship_candidate.dart';
import 'narrative_relationship_context.dart';
import 'narrative_relationship_guards.dart';
import 'narrative_relationship_kind_resolver.dart';
import 'narrative_relationship_pairing.dart';
import 'narrative_relationship_signals.dart';
import 'narrative_spread_semantics.dart';

abstract final class NarrativeRelationshipScorer {
  NarrativeRelationshipScorer._();

  static NarrativePairEvaluation evaluate({
    required NarrativeRelationshipCardContext a,
    required NarrativeRelationshipCardContext b,
    required SpreadSemanticDefinition spread,
    required QuestionKind questionKind,
  }) {
    final (left, right) = NarrativeRelationshipPairing.normalizePair(a, b);
    final pos = NarrativeRelationshipPairing.matchPositions(
      spread: spread,
      left: left,
      right: right,
    );
    final s = NarrativeRelationshipSignalBundle.compute(
      left: left,
      right: right,
      pos: pos,
      questionKind: questionKind,
    );

    final hasSemantic = s.overlap > 0;
    final hasContrast = s.contrastClass != null;
    final hasTransform = s.effective.isNotEmpty;
    final hasPosition = pos.edgeKind != null;
    final hasQuestion = s.question > 0;
    final families = [
      hasSemantic,
      hasContrast,
      hasTransform,
      s.canonical,
      hasPosition,
      hasQuestion,
    ].where((v) => v).length;

    final standard = families >= 2 && s.total >= 1.25;
    final canonicalPath = s.canonical && families >= 2 && s.total >= 1.0;
    final positionStrong =
        hasPosition &&
        (hasSemantic || hasContrast || hasTransform) &&
        s.total >= 1.0;
    final normalAdmitted = standard || canonicalPath || positionStrong;

    final higher = NarrativeRelationshipKindResolver.higherPriority(
      contrastClass: s.contrastClass,
      edgeKind: pos.edgeKind,
      directed: pos.directed,
      leftRole: pos.leftRole,
      rightRole: pos.rightRole,
      sharedSemantic: s.sharedSemantic.toSet(),
      effectiveTransforms: s.effective,
      hasSemantic: hasSemantic,
      independentFamilyCount: families,
    );

    final themeEligible =
        s.overlap >= 2.0 &&
        s.sharedSemantic.any(
          (id) =>
              NarrativeKeywordDiscrimination.df(id) <
              NarrativeKeywordDiscrimination.highFrequencyDfThreshold,
        );

    return NarrativePairEvaluation(
      left: left,
      right: right,
      breakdown: NarrativeRelationshipScoreBreakdown(
        overlap: s.overlap,
        contrast: s.contrast,
        transform: s.transformScore,
        canonical: s.canonicalScore,
        position: s.positionScore,
        question: s.question,
        total: s.total,
      ),
      sharedSemanticIds: List.unmodifiable(s.sharedSemantic),
      sharedKeywordIds: List.unmodifiable(s.sharedKeywords),
      sharedTagOnlyIds: List.unmodifiable(s.sharedTagOnly),
      contrastClass: s.contrastClass,
      effectiveSharedTransforms: s.effective,
      canonicalRelated: s.canonical,
      positionEdgeKind: pos.edgeKind,
      questionRelevant: hasQuestion,
      independentFamilyCount: families,
      standardPath: standard,
      canonicalPath: canonicalPath,
      positionStrongPath: positionStrong,
      normalAdmitted: normalAdmitted,
      pageSuitGuard: s.pageGuard,
      courtRankGuard: s.courtGuard,
      themePairEligible: themeEligible,
      higherPriorityKind: higher,
      provenanceTokens: NarrativeRelationshipGuards.provenanceTokens(
        sharedKeywords: s.sharedKeywords,
        sharedTagOnly: s.sharedTagOnly,
        sharedSemantic: s.sharedSemantic,
        left: left,
        right: right,
        contrastClass: s.contrastClass,
        effective: s.effective,
        canonical: s.canonical,
        hasPosition: hasPosition,
        question: s.question,
        pageGuard: s.pageGuard,
        courtGuard: s.courtGuard,
      ),
      strength: s.strength,
    );
  }
}
