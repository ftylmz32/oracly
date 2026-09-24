/// Phase 6C.2 — relationship strength finite unit-interval red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_evidence.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  test('relationship strength nan/inf/out-of-range rejected; 0/1 ok', () {
    final three = buildFromCorpusId('three_contrast_exemplar_en');
    final a = three.cards[0];
    final b = three.cards[1];
    TarotNarrativeRelationshipEvidence rel(double strength) {
      return TarotNarrativeRelationshipEvidence(
        evidenceId: 'x',
        leftCardId: a.canonicalCardId,
        rightCardId: b.canonicalCardId,
        leftPositionKey: a.positionKey,
        rightPositionKey: b.positionKey,
        kind: RelationshipKind.contrast,
        provenance: 't',
        strength: strength,
      );
    }

    for (final s in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
      -0.01,
      1.01,
    ]) {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(three, relationships: [rel(s)]),
        ),
        throwsArgumentError,
      );
    }
    for (final s in [0.0, 1.0]) {
      expect(
        NarrativeTarotPromptSerializer.serialize(
          copyRequest(three, relationships: [rel(s)]),
        ).relationships.first.strength,
        s,
      );
    }
  });
}
