/// Theme cluster + ranking comparators (3D.1C helper).
library;

import 'narrative_keyword_discrimination.dart';
import 'narrative_relationship_candidate.dart';
import 'narrative_relationship_context.dart';

abstract final class NarrativeRelationshipRanking {
  NarrativeRelationshipRanking._();

  static int cardOrder(
    NarrativeRelationshipCardContext a,
    NarrativeRelationshipCardContext b,
  ) {
    final byIndex = a.positionIndex.compareTo(b.positionIndex);
    if (byIndex != 0) return byIndex;
    return a.canonicalCardId.compareTo(b.canonicalCardId);
  }

  static Set<String> clusterEligibleIds(
    List<NarrativeRelationshipCardContext> cards,
  ) {
    final counts = <String, int>{};
    for (final c in cards) {
      for (final id in c.semanticChannel.semanticIds.toSet()) {
        if (NarrativeKeywordDiscrimination.df(id) > 6) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return {
      for (final e in counts.entries)
        if (e.value >= 3) e.key,
    };
  }

  static int themeOrder(NarrativePairEvaluation a, NarrativePairEvaluation b) {
    final byOverlap = b.breakdown.overlap.compareTo(a.breakdown.overlap);
    if (byOverlap != 0) return byOverlap;
    final da = (a.left.positionIndex - a.right.positionIndex).abs();
    final db = (b.left.positionIndex - b.right.positionIndex).abs();
    final byDist = da.compareTo(db);
    if (byDist != 0) return byDist;
    final minA = _minIndex(a.left.positionIndex, a.right.positionIndex);
    final minB = _minIndex(b.left.positionIndex, b.right.positionIndex);
    final byMin = minA.compareTo(minB);
    if (byMin != 0) return byMin;
    final byLeft = a.left.canonicalCardId.compareTo(b.left.canonicalCardId);
    if (byLeft != 0) return byLeft;
    return a.right.canonicalCardId.compareTo(b.right.canonicalCardId);
  }

  static int rankOrder(
    NarrativeRelationshipCandidate a,
    NarrativeRelationshipCandidate b,
  ) {
    final byStrength = b.strength.compareTo(a.strength);
    if (byStrength != 0) return byStrength;
    final da = (a.leftPositionIndex - a.rightPositionIndex).abs();
    final db = (b.leftPositionIndex - b.rightPositionIndex).abs();
    final byDist = da.compareTo(db);
    if (byDist != 0) return byDist;
    final minA = _minIndex(a.leftPositionIndex, a.rightPositionIndex);
    final minB = _minIndex(b.leftPositionIndex, b.rightPositionIndex);
    final byMin = minA.compareTo(minB);
    if (byMin != 0) return byMin;
    final byLeft = a.leftCanonicalId.compareTo(b.leftCanonicalId);
    if (byLeft != 0) return byLeft;
    return a.rightCanonicalId.compareTo(b.rightCanonicalId);
  }

  static int _minIndex(int a, int b) => a < b ? a : b;

  static bool samePair(NarrativePairEvaluation a, NarrativePairEvaluation b) =>
      a.left.canonicalCardId == b.left.canonicalCardId &&
      a.right.canonicalCardId == b.right.canonicalCardId &&
      a.left.positionKey == b.left.positionKey &&
      a.right.positionKey == b.right.positionKey;
}
