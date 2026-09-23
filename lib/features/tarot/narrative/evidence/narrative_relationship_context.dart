/// Prepared card + position pair context for relationship scoring (3D.1C).
library;

import '../../deck/oracly_tarot_enums.dart';
import '../domain/reversed_transform_kind.dart';
import 'narrative_semantic_channel.dart';
import 'narrative_spread_semantics.dart';

class NarrativeRelationshipCardContext {
  NarrativeRelationshipCardContext({
    required this.canonicalCardId,
    required this.positionKey,
    required this.positionIndex,
    required this.isReversed,
    required this.suit,
    required this.number,
    required Iterable<String> keywordIds,
    required this.semanticChannel,
    required Iterable<ReversedTransformKind> transforms,
    required Iterable<String> relatedIds,
  }) : keywordIds = List<String>.unmodifiable(List<String>.from(keywordIds)),
       transforms = List<ReversedTransformKind>.unmodifiable(
         List<ReversedTransformKind>.from(transforms),
       ),
       relatedIds = List<String>.unmodifiable(List<String>.from(relatedIds));

  final String canonicalCardId;
  final String positionKey;
  final int positionIndex;
  final bool isReversed;
  final OraclyTarotSuit suit;
  final int number;
  final List<String> keywordIds;
  final NarrativeSemanticChannel semanticChannel;
  final List<ReversedTransformKind> transforms;
  final List<String> relatedIds;
}

class NarrativePositionPairMatch {
  const NarrativePositionPairMatch({
    required this.edgeKind,
    required this.directed,
    required this.fromPositionKey,
    required this.toPositionKey,
    required this.leftRole,
    required this.rightRole,
  });

  final PositionEdgeKind? edgeKind;
  final bool directed;
  final String? fromPositionKey;
  final String? toPositionKey;
  final PositionRole leftRole;
  final PositionRole rightRole;
}
