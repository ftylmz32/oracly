/// Shared builders for 3D.1C relationship scorer/selector tests.
library;

import 'package:oracly_new/features/tarot/deck/oracly_tarot_enums.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_semantic_channel.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';

NarrativeRelationshipCardContext ctx({
  required String id,
  required String positionKey,
  required int positionIndex,
  bool isReversed = false,
  OraclyTarotSuit suit = OraclyTarotSuit.cups,
  int number = 1,
  List<String> keywordIds = const [],
  List<String> symbolTags = const [],
  List<ReversedTransformKind> transforms = const [],
  List<String> relatedIds = const [],
}) {
  return NarrativeRelationshipCardContext(
    canonicalCardId: id,
    positionKey: positionKey,
    positionIndex: positionIndex,
    isReversed: isReversed,
    suit: suit,
    number: number,
    keywordIds: keywordIds,
    semanticChannel: NarrativeSemanticChannel.from(
      keywordIds: keywordIds,
      symbolTags: symbolTags,
    ),
    transforms: transforms,
    relatedIds: relatedIds,
  );
}

SpreadSemanticDefinition threeCard() =>
    ClassicalSpreadSemantics.byLegacyTypeName('threeCard');

SpreadSemanticDefinition celtic() =>
    ClassicalSpreadSemantics.byLegacyTypeName('celticCross');
