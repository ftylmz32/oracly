/// Phase 6A.1 — provider identity fail-closed + scorer/selector mismatch.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edge_provider.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_edge_provider.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_spread_resolver.dart';

import '../narrative_evidence/narrative_relationship_test_support.dart';

SpreadSemanticDefinition _crossroads() =>
    const SignatureNarrativeSpreadResolver().resolve(
      TarotSpreadType.crossroads,
    );

List<NarrativeRelationshipCardContext> ctxCrossroads() {
  final s = _crossroads();
  return [
    for (final p in s.positions)
      ctx(
        id: 'c_${p.positionKey}',
        positionKey: p.positionKey,
        positionIndex: p.index,
        keywordIds: [
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.attachment,
        ],
      ),
  ];
}

void main() {
  const classical = ClassicalPositionEdgeProvider();
  const signature = SignatureNarrativeEdgeProvider();

  group('ClassicalPositionEdgeProvider identity', () {
    test('valid Classical spreads retain edge counts', () {
      expect(kAuthoritativePositionEdges, hasLength(29));
      final expected = {
        'single': 0,
        'threeCard': 3,
        'fiveCard': 6,
        'sevenCard': 8,
        'celticCross': 12,
      };
      for (final e in expected.entries) {
        final spread = ClassicalSpreadSemantics.byLegacyTypeName(e.key);
        expect(classical.edgesFor(spread), hasLength(e.value));
      }
    });

    test('real Crossroads projection throws — not empty', () {
      expect(
        () => classical.edgesFor(_crossroads()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('spoofed Classical identities throw', () {
      final three = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
      expect(
        () => classical.edgesFor(
          SpreadSemanticDefinition(
            spreadId: 'signature.fake',
            legacyTypeName: 'threeCard',
            cardCount: 3,
            purposeKey: three.purposeKey,
            positions: three.positions,
            interpretationOrder: three.interpretationOrder,
            geometryHook: three.geometryHook,
            lengthBand: three.lengthBand,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => classical.edgesFor(
          SpreadSemanticDefinition(
            spreadId: 'classical.threeCard',
            legacyTypeName: 'fiveCard',
            cardCount: 5,
            purposeKey: three.purposeKey,
            positions: three.positions,
            interpretationOrder: three.interpretationOrder,
            geometryHook: three.geometryHook,
            lengthBand: three.lengthBand,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => classical.edgesFor(
          SpreadSemanticDefinition(
            spreadId: 'classical.threeCard',
            legacyTypeName: 'threeCard',
            cardCount: 5,
            purposeKey: three.purposeKey,
            positions: three.positions,
            interpretationOrder: three.interpretationOrder,
            geometryHook: three.geometryHook,
            lengthBand: three.lengthBand,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SignatureNarrativeEdgeProvider identity', () {
    test('spoofed Signature identities throw', () {
      final real = _crossroads();
      expect(
        () => signature.edgesFor(
          SpreadSemanticDefinition(
            spreadId: 'signature.crossroads',
            legacyTypeName: 'fiveCard',
            cardCount: 5,
            purposeKey: real.purposeKey,
            positions: real.positions,
            interpretationOrder: real.interpretationOrder,
            geometryHook: real.geometryHook,
            lengthBand: real.lengthBand,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => signature.edgesFor(
          SpreadSemanticDefinition(
            spreadId: 'signature.crossroads',
            legacyTypeName: 'crossroads',
            cardCount: 3,
            purposeKey: real.purposeKey,
            positions: real.positions,
            interpretationOrder: real.interpretationOrder,
            geometryHook: real.geometryHook,
            lengthBand: real.lengthBand,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => signature.edgesFor(
          SpreadSemanticDefinition(
            spreadId: 'classical.fiveCard',
            legacyTypeName: 'crossroads',
            cardCount: 5,
            purposeKey: real.purposeKey,
            positions: real.positions,
            interpretationOrder: real.interpretationOrder,
            geometryHook: real.geometryHook,
            lengthBand: real.lengthBand,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => signature.edgesFor(threeCard()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('real Crossroads still yields four edges', () {
      expect(signature.edgesFor(_crossroads()), hasLength(4));
    });
  });

  group('default Classical provider + Crossroads scorer/selector', () {
    test('scorer fails closed without Signature provider', () {
      final cards = ctxCrossroads();
      expect(
        () => NarrativeRelationshipScorer.evaluate(
          a: cards[0],
          b: cards[1],
          spread: _crossroads(),
          questionKind: QuestionKind.open,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('selector fails closed without Signature provider', () {
      expect(
        () => NarrativeRelationshipSelector.select(
          cards: ctxCrossroads(),
          spread: _crossroads(),
          questionKind: QuestionKind.open,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('explicit Signature provider still scores Crossroads edges', () {
      final cards = ctxCrossroads();
      final ab = NarrativeRelationshipScorer.evaluate(
        a: cards[0], // option_a
        b: cards[1], // option_b
        spread: _crossroads(),
        questionKind: QuestionKind.open,
        edgeProvider: signature,
      );
      expect(ab.positionEdgeKind, PositionEdgeKind.opposition);

      final ta = NarrativeRelationshipScorer.evaluate(
        a: cards[2], // tension
        b: cards[0], // option_a
        spread: _crossroads(),
        questionKind: QuestionKind.open,
        edgeProvider: signature,
      );
      expect(ta.positionEdgeKind, PositionEdgeKind.pressure);

      final cd = NarrativeRelationshipScorer.evaluate(
        a: cards[3], // counsel
        b: cards[4], // direction
        spread: _crossroads(),
        questionKind: QuestionKind.open,
        edgeProvider: signature,
      );
      expect(cd.positionEdgeKind, PositionEdgeKind.supportive);

      final selected = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: _crossroads(),
        questionKind: QuestionKind.open,
        edgeProvider: signature,
      );
      expect(selected, isNotEmpty);
    });
  });
}
