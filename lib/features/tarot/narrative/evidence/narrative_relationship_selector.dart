/// Pair generation, theme finalization, ranking, evidence ids (3D.1C).
library;

import 'narrative_question_grounding.dart';
import 'narrative_relationship_candidate.dart';
import 'narrative_relationship_context.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_relationship_kind_resolver.dart';
import 'narrative_relationship_ranking.dart';
import 'narrative_relationship_rules.dart';
import 'narrative_relationship_scorer.dart';
import 'narrative_spread_semantics.dart';

abstract final class NarrativeRelationshipSelector {
  NarrativeRelationshipSelector._();

  static List<TarotNarrativeRelationshipEvidence> select({
    required List<NarrativeRelationshipCardContext> cards,
    required SpreadSemanticDefinition spread,
    required QuestionKind questionKind,
    int maxRelationships = NarrativeRelationshipRules.maxRelationshipsDefault,
  }) {
    final sorted = [...cards]..sort(NarrativeRelationshipRanking.cardOrder);
    final evaluations = <NarrativePairEvaluation>[];
    for (var i = 0; i < sorted.length; i++) {
      for (var j = i + 1; j < sorted.length; j++) {
        evaluations.add(
          NarrativeRelationshipScorer.evaluate(
            a: sorted[i],
            b: sorted[j],
            spread: spread,
            questionKind: questionKind,
          ),
        );
      }
    }

    final clusterIds = NarrativeRelationshipRanking.clusterEligibleIds(sorted);
    final themeWinner = _pickThemeWinner(evaluations, clusterIds);

    final candidates = <NarrativeRelationshipCandidate>[];
    for (final ev in evaluations) {
      final cand = _finalize(ev, themeWinner);
      if (cand != null) candidates.add(cand);
    }

    candidates.sort(NarrativeRelationshipRanking.rankOrder);
    final top = candidates.take(maxRelationships).toList();
    return [
      for (var i = 0; i < top.length; i++)
        TarotNarrativeRelationshipEvidence(
          evidenceId: 'rel_${(i + 1).toString().padLeft(2, '0')}',
          leftCardId: top[i].leftCanonicalId,
          rightCardId: top[i].rightCanonicalId,
          leftPositionKey: top[i].leftPositionKey,
          rightPositionKey: top[i].rightPositionKey,
          kind: top[i].kind,
          provenance: top[i].provenanceTokens.join('|'),
          strength: top[i].strength,
          noteKeyOrText: null,
        ),
    ];
  }

  static NarrativeRelationshipCandidate? _finalize(
    NarrativePairEvaluation ev,
    NarrativePairEvaluation? themeWinner,
  ) {
    RelationshipKind? kind = ev.higherPriorityKind;
    final tokens = <String>{...ev.provenanceTokens};
    final isThemeWinner =
        themeWinner != null &&
        NarrativeRelationshipRanking.samePair(ev, themeWinner);

    if (kind == null && isThemeWinner) {
      kind = RelationshipKind.themeRepetition;
      tokens.add('themeEcho');
    } else if (kind == null && ev.normalAdmitted && ev.breakdown.overlap > 0) {
      kind = NarrativeRelationshipKindResolver.supportOrReinforcement(
        ev.sharedSemanticIds.toSet(),
      );
    }
    if (kind == null) return null;

    final sortedTokens = tokens.toList()..sort();
    return NarrativeRelationshipCandidate(
      leftCanonicalId: ev.left.canonicalCardId,
      rightCanonicalId: ev.right.canonicalCardId,
      leftPositionKey: ev.left.positionKey,
      rightPositionKey: ev.right.positionKey,
      leftPositionIndex: ev.left.positionIndex,
      rightPositionIndex: ev.right.positionIndex,
      kind: kind,
      strength: ev.strength,
      totalScore: ev.breakdown.total,
      provenanceTokens: List.unmodifiable(sortedTokens),
      pageSuitGuard: ev.pageSuitGuard,
      courtRankGuard: ev.courtRankGuard,
      sharedSemanticIds: ev.sharedSemanticIds,
    );
  }

  static NarrativePairEvaluation? _pickThemeWinner(
    List<NarrativePairEvaluation> evaluations,
    Set<String> clusterIds,
  ) {
    final eligible = evaluations.where((ev) {
      if (ev.higherPriorityKind != null) return false;
      final pairOk = ev.themePairEligible;
      final clusterOk = ev.sharedSemanticIds.any(clusterIds.contains);
      return pairOk || clusterOk;
    }).toList();
    if (eligible.isEmpty) return null;
    eligible.sort(NarrativeRelationshipRanking.themeOrder);
    return eligible.first;
  }
}
