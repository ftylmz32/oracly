/// Phase 6C.1 — interpretation order + position definition red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';

import 'narrative_prompt_test_support.dart';

void main() {
  group('Interpretation order matrix', () {
    late TarotNarrativeRequest three;

    setUp(() {
      three = buildFromCorpusId('three_contrast_exemplar_en');
    });

    test('duplicate [0,0,1] throws', () {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            three,
            spread: withInterpretationOrder(three.spread, const [0, 0, 1]),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('missing [0,1] throws', () {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            three,
            spread: withInterpretationOrder(three.spread, const [0, 1]),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('out of range [0,1,3] throws', () {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            three,
            spread: withInterpretationOrder(three.spread, const [0, 1, 3]),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('negative [-1,0,1] throws', () {
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(
            three,
            spread: withInterpretationOrder(three.spread, const [-1, 0, 1]),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('valid permutation [2,0,1] orders cards', () {
      final input = NarrativeTarotPromptSerializer.serialize(
        copyRequest(
          three,
          spread: withInterpretationOrder(three.spread, const [2, 0, 1]),
        ),
      );
      expect([for (final c in input.cards) c.positionIndex], [2, 0, 1]);
    });
  });

  group('Position definition red-team', () {
    test('duplicate key throws', () {
      final base = buildFromCorpusId('three_contrast_exemplar_en');
      final s = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
      final dupKey = SpreadSemanticDefinition(
        spreadId: s.spreadId,
        legacyTypeName: s.legacyTypeName,
        cardCount: 3,
        purposeKey: s.purposeKey,
        positions: [
          s.positions[0],
          s.positions[1],
          SpreadPositionSemantic(
            positionKey: s.positions[0].positionKey,
            index: 2,
            role: s.positions[2].role,
            guidingQuestionKey: s.positions[2].guidingQuestionKey,
            temporal: s.positions[2].temporal,
            relationToOtherSlots: s.positions[2].relationToOtherSlots,
            weight: s.positions[2].weight,
            displayLabelKey: s.positions[2].displayLabelKey,
          ),
        ],
        interpretationOrder: s.interpretationOrder,
        geometryHook: s.geometryHook,
        lengthBand: s.lengthBand,
      );
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(base, spread: dupKey, relationships: const []),
        ),
        throwsArgumentError,
      );
    });

    test('duplicate index throws', () {
      final base = buildFromCorpusId('three_contrast_exemplar_en');
      final s = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
      final dup = SpreadSemanticDefinition(
        spreadId: s.spreadId,
        legacyTypeName: s.legacyTypeName,
        cardCount: 3,
        purposeKey: s.purposeKey,
        positions: [
          s.positions[0],
          s.positions[1],
          SpreadPositionSemantic(
            positionKey: 'extra_slot',
            index: 1,
            role: s.positions[2].role,
            guidingQuestionKey: s.positions[2].guidingQuestionKey,
            temporal: s.positions[2].temporal,
            relationToOtherSlots: const [],
            weight: 1,
            displayLabelKey: s.positions[2].displayLabelKey,
          ),
        ],
        interpretationOrder: s.interpretationOrder,
        geometryHook: s.geometryHook,
        lengthBand: s.lengthBand,
      );
      expect(
        () => NarrativeTarotPromptSerializer.serialize(
          copyRequest(base, spread: dup, relationships: const []),
        ),
        throwsArgumentError,
      );
    });
  });
}
