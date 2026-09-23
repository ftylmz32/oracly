/// FR guards + provenance token assembly (3D.1C helper).
library;

import '../../deck/oracly_tarot_enums.dart';
import 'narrative_keyword_contrasts.dart';
import 'narrative_relationship_context.dart';
import '../domain/reversed_transform_kind.dart';

abstract final class NarrativeRelationshipGuards {
  NarrativeRelationshipGuards._();

  static bool pageSuitGuard(
    NarrativeRelationshipCardContext a,
    NarrativeRelationshipCardContext b,
  ) {
    if (a.number != OraclyTarotRanks.page ||
        b.number != OraclyTarotRanks.page) {
      return false;
    }
    if (a.suit == b.suit) return false;
    return _keywordSetsEqual(a.keywordIds, b.keywordIds);
  }

  static bool courtRankGuard(
    NarrativeRelationshipCardContext a,
    NarrativeRelationshipCardContext b,
  ) {
    if (a.suit != b.suit) return false;
    final ranks = {a.number, b.number};
    if (!ranks.contains(OraclyTarotRanks.page) ||
        !ranks.contains(OraclyTarotRanks.knight) ||
        ranks.length != 2) {
      return false;
    }
    return _keywordSetsEqual(a.keywordIds, b.keywordIds);
  }

  static bool _keywordSetsEqual(List<String> a, List<String> b) {
    final ak = a.toSet();
    final bk = b.toSet();
    return ak.length == bk.length && ak.containsAll(bk);
  }

  static NarrativeKeywordContrastClass? maxContrast(
    NarrativeRelationshipCardContext left,
    NarrativeRelationshipCardContext right,
  ) {
    NarrativeKeywordContrastClass? best;
    for (final a in left.semanticChannel.semanticIds) {
      for (final b in right.semanticChannel.semanticIds) {
        final c = NarrativeKeywordContrasts.between(a, b);
        if (c == null) continue;
        if (c == NarrativeKeywordContrastClass.hard) return c;
        best ??= c;
      }
    }
    return best;
  }

  static List<String> provenanceTokens({
    required List<String> sharedKeywords,
    required List<String> sharedTagOnly,
    required List<String> sharedSemantic,
    required NarrativeRelationshipCardContext left,
    required NarrativeRelationshipCardContext right,
    required NarrativeKeywordContrastClass? contrastClass,
    required List<ReversedTransformKind> effective,
    required bool canonical,
    required bool hasPosition,
    required double question,
    required bool pageGuard,
    required bool courtGuard,
  }) {
    final tokens = <String>{};
    if (sharedKeywords.isNotEmpty) tokens.add('keywordOverlap');
    if (contrastClass != null) tokens.add('keywordContrast');
    final tagContrib = sharedSemantic.any(
      (id) =>
          left.semanticChannel.ontologyTagIds.contains(id) ||
          right.semanticChannel.ontologyTagIds.contains(id),
    );
    if (sharedTagOnly.isNotEmpty || tagContrib) tokens.add('symbolTag');
    if (effective.isNotEmpty) tokens.add('transform');
    if (canonical) tokens.add('canonicalRelation');
    if (hasPosition) tokens.add('positionEdge');
    if (left.isReversed != right.isReversed &&
        (contrastClass != null || effective.isNotEmpty)) {
      tokens.add('orientationPair');
    }
    if (question > 0) tokens.add('questionRelevance');
    if (pageGuard) tokens.add('pageSuitGuard');
    if (courtGuard) tokens.add('courtRankGuard');
    final sorted = tokens.toList()..sort();
    return List.unmodifiable(sorted);
  }
}
