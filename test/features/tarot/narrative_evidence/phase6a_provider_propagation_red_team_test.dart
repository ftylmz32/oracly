/// Phase 6A — scorer/selector explicit provider propagation + red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edge_provider.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edges.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_pairing.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_scorer.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_selector.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantic_resolver.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_edge_provider.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_spread_resolver.dart';

import 'narrative_relationship_test_support.dart';

/// Test-only provider: past↔present becomes opposition (not temporal).
final class _StubOppositionProvider implements NarrativePositionEdgeProvider {
  const _StubOppositionProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) {
    return List.unmodifiable(const [
      AuthoritativePositionEdge(
        legacyTypeName: 'threeCard',
        fromPositionKey: 'past',
        toPositionKey: 'present',
        directed: false,
        edgeKind: PositionEdgeKind.opposition,
      ),
    ]);
  }
}

/// Duplicate-edge provider for red-team.
final class _DuplicateEdgeProvider implements NarrativePositionEdgeProvider {
  const _DuplicateEdgeProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) {
    return List.unmodifiable(const [
      AuthoritativePositionEdge(
        legacyTypeName: 'threeCard',
        fromPositionKey: 'past',
        toPositionKey: 'present',
        directed: true,
        edgeKind: PositionEdgeKind.temporal,
      ),
      AuthoritativePositionEdge(
        legacyTypeName: 'threeCard',
        fromPositionKey: 'past',
        toPositionKey: 'present',
        directed: true,
        edgeKind: PositionEdgeKind.supportive,
      ),
    ]);
  }
}

final class _EmptyEdgeProvider implements NarrativePositionEdgeProvider {
  const _EmptyEdgeProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) =>
      const [];
}

void main() {
  group('explicit provider propagation', () {
    test('scorer consumes stub edge kind', () {
      final a = ctx(
        id: 'a',
        positionKey: 'past',
        positionIndex: 0,
        keywordIds: [
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.attachment,
        ],
      );
      final b = ctx(
        id: 'b',
        positionKey: 'present',
        positionIndex: 1,
        keywordIds: [
          NarrativeKeywordIds.abundance,
          NarrativeKeywordIds.attachment,
        ],
      );
      final classical = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      final stubbed = NarrativeRelationshipScorer.evaluate(
        a: a,
        b: b,
        spread: threeCard(),
        questionKind: QuestionKind.open,
        edgeProvider: const _StubOppositionProvider(),
      );
      expect(classical.positionEdgeKind, PositionEdgeKind.temporal);
      expect(stubbed.positionEdgeKind, PositionEdgeKind.opposition);
      expect(stubbed.breakdown.position, isNot(classical.breakdown.position));
    });

    test('selector threads same stub through pairs', () {
      final cards = [
        ctx(
          id: 'a',
          positionKey: 'past',
          positionIndex: 0,
          keywordIds: [
            NarrativeKeywordIds.abundance,
            NarrativeKeywordIds.attachment,
          ],
        ),
        ctx(
          id: 'b',
          positionKey: 'present',
          positionIndex: 1,
          keywordIds: [
            NarrativeKeywordIds.abundance,
            NarrativeKeywordIds.attachment,
          ],
        ),
        ctx(id: 'c', positionKey: 'future', positionIndex: 2),
      ];
      final classical = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: threeCard(),
        questionKind: QuestionKind.open,
      );
      final stubbed = NarrativeRelationshipSelector.select(
        cards: cards,
        spread: threeCard(),
        questionKind: QuestionKind.open,
        edgeProvider: const _StubOppositionProvider(),
      );
      // Same admitted set may share provenance token labels; strength must
      // reflect different position contributions from the stub provider.
      expect(
        classical.map((e) => e.strength).toList(),
        isNot(equals(stubbed.map((e) => e.strength).toList())),
      );
      expect(stubbed, isNotEmpty);
    });
  });

  group('red-team', () {
    test('Classical resolver rejects Crossroads', () {
      expect(
        () => const ClassicalSpreadSemanticResolver()
            .resolve(TarotSpreadType.crossroads),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Signature resolver rejects Classical', () {
      expect(
        () => const SignatureNarrativeSpreadResolver()
            .resolve(TarotSpreadType.fiveCard),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Classical edge provider rejects Crossroads fail-closed', () {
      final projected = const SignatureNarrativeSpreadResolver().resolve(
        TarotSpreadType.crossroads,
      );
      expect(
        () => const ClassicalPositionEdgeProvider().edgesFor(projected),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        kAuthoritativePositionEdges
            .where((e) => e.legacyTypeName == 'crossroads'),
        isEmpty,
      );
    });

    test('Classical edge provider rejects spoofed identities', () {
      final three = ClassicalSpreadSemantics.byLegacyTypeName('threeCard');
      expect(
        () => const ClassicalPositionEdgeProvider().edgesFor(
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
        () => const ClassicalPositionEdgeProvider().edgesFor(
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

    test('Signature edge provider rejects Classical', () {
      expect(
        () => const SignatureNarrativeEdgeProvider().edgesFor(threeCard()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('duplicate custom provider edges still fail', () {
      expect(
        () => NarrativeRelationshipPairing.matchPositions(
          spread: threeCard(),
          left: ctx(id: 'a', positionKey: 'past', positionIndex: 0),
          right: ctx(id: 'b', positionKey: 'present', positionIndex: 1),
          edgeProvider: const _DuplicateEdgeProvider(),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('unknown positions still fail', () {
      expect(
        () => NarrativeRelationshipPairing.matchPositions(
          spread: threeCard(),
          left: ctx(id: 'a', positionKey: 'nope', positionIndex: 0),
          right: ctx(id: 'b', positionKey: 'present', positionIndex: 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('empty provider yields valid no-edge result', () {
      final m = NarrativeRelationshipPairing.matchPositions(
        spread: threeCard(),
        left: ctx(id: 'a', positionKey: 'past', positionIndex: 0),
        right: ctx(id: 'b', positionKey: 'present', positionIndex: 1),
        edgeProvider: const _EmptyEdgeProvider(),
      );
      expect(m.edgeKind, isNull);
      expect(m.fromPositionKey, isNull);
    });

    test('global table row count unchanged at 29', () {
      expect(kAuthoritativePositionEdges.length, 29);
      expect(ClassicalSpreadSemantics.all, hasLength(5));
    });
  });
}
