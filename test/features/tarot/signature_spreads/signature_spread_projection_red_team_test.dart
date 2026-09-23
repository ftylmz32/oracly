/// Phase 5B — negative red-team projection validation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads_edges.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_edge.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projection_validation.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projector.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_semantic_projection.dart';

void main() {
  final crossSrc = SignatureSpreadCatalog.launch[3];
  final good = SignatureSpreadProjector.project(crossSrc);

  SignatureSpreadSemanticProjection withEdges(List<SignatureSpreadEdge> edges) {
    return SignatureSpreadSemanticProjection(
      source: crossSrc,
      projected: good.projected,
      edges: edges,
    );
  }

  SignatureSpreadSemanticProjection withProjected(
    SpreadSemanticDefinition projected, {
    List<SignatureSpreadEdge>? edges,
  }) {
    return SignatureSpreadSemanticProjection(
      source: crossSrc,
      projected: projected,
      edges: edges ?? good.edges,
    );
  }

  group('projection red-team', () {
    test('unknown edge position', () {
      final r = SignatureProjectionValidation.validate(
        withEdges([
          ...kSignatureCrossroadsEdges.take(3),
          const SignatureSpreadEdge(
            fromPositionKey: 'tension',
            toPositionKey: 'ghost',
            directed: false,
            edgeKind: PositionEdgeKind.pressure,
          ),
        ]),
      );
      expect(r.violations, contains(SignatureProjectionViolation.unknownEdgeEndpoint));
    });

    test('self edge', () {
      final r = SignatureProjectionValidation.validate(
        withEdges([
          const SignatureSpreadEdge(
            fromPositionKey: 'tension',
            toPositionKey: 'tension',
            directed: false,
            edgeKind: PositionEdgeKind.pressure,
          ),
        ]),
      );
      expect(r.violations, contains(SignatureProjectionViolation.selfEdge));
    });

    test('duplicate undirected pair reversed', () {
      final r = SignatureProjectionValidation.validate(
        withEdges(const [
          SignatureSpreadEdge(
            fromPositionKey: 'option_a',
            toPositionKey: 'option_b',
            directed: false,
            edgeKind: PositionEdgeKind.opposition,
          ),
          SignatureSpreadEdge(
            fromPositionKey: 'option_b',
            toPositionKey: 'option_a',
            directed: false,
            edgeKind: PositionEdgeKind.opposition,
          ),
        ]),
      );
      expect(r.violations, contains(SignatureProjectionViolation.duplicateEdgePair));
    });

    test('duplicate directed/undirected pair collision', () {
      final r = SignatureProjectionValidation.validate(
        withEdges(const [
          SignatureSpreadEdge(
            fromPositionKey: 'counsel',
            toPositionKey: 'direction',
            directed: true,
            edgeKind: PositionEdgeKind.supportive,
          ),
          SignatureSpreadEdge(
            fromPositionKey: 'counsel',
            toPositionKey: 'direction',
            directed: false,
            edgeKind: PositionEdgeKind.supportive,
          ),
        ]),
      );
      expect(r.violations, contains(SignatureProjectionViolation.duplicateEdgePair));
    });

    test('empty endpoint', () {
      final r = SignatureProjectionValidation.validate(
        withEdges(const [
          SignatureSpreadEdge(
            fromPositionKey: '',
            toPositionKey: 'direction',
            directed: true,
            edgeKind: PositionEdgeKind.supportive,
          ),
        ]),
      );
      expect(r.violations, contains(SignatureProjectionViolation.emptyEdgeEndpoint));
    });

    test('Crossroads missing one locked edge', () {
      final r = SignatureProjectionValidation.validate(
        withEdges(kSignatureCrossroadsEdges.take(3).toList()),
      );
      expect(r.violations, contains(SignatureProjectionViolation.crossroadsEdgeCount));
    });

    test('Crossroads extra fifth edge', () {
      final r = SignatureProjectionValidation.validate(
        withEdges([
          ...kSignatureCrossroadsEdges,
          const SignatureSpreadEdge(
            fromPositionKey: 'option_a',
            toPositionKey: 'direction',
            directed: false,
            edgeKind: PositionEdgeKind.temporal,
          ),
        ]),
      );
      expect(r.violations, contains(SignatureProjectionViolation.crossroadsEdgeCount));
    });

    test('incorrect directed flag', () {
      final edges = [
        const SignatureSpreadEdge(
          fromPositionKey: 'option_a',
          toPositionKey: 'option_b',
          directed: true,
          edgeKind: PositionEdgeKind.opposition,
        ),
        ...kSignatureCrossroadsEdges.skip(1),
      ];
      final r = SignatureProjectionValidation.validate(withEdges(edges));
      expect(r.violations, contains(SignatureProjectionViolation.crossroadsEdgeCount));
    });

    test('wrong edge kind', () {
      final edges = [
        const SignatureSpreadEdge(
          fromPositionKey: 'option_a',
          toPositionKey: 'option_b',
          directed: false,
          edgeKind: PositionEdgeKind.temporal,
        ),
        ...kSignatureCrossroadsEdges.skip(1),
      ];
      final r = SignatureProjectionValidation.validate(withEdges(edges));
      expect(r.violations, contains(SignatureProjectionViolation.crossroadsEdgeCount));
    });

    test('wrong temporal orientation', () {
      final positions = [
        for (final p in good.projected.positions)
          SpreadPositionSemantic(
            positionKey: p.positionKey,
            index: p.index,
            role: p.role,
            guidingQuestionKey: p.guidingQuestionKey,
            temporal: p.positionKey == 'direction'
                ? TemporalOrientation.atemporal
                : p.temporal,
            relationToOtherSlots: p.relationToOtherSlots,
            weight: p.weight,
            displayLabelKey: p.displayLabelKey,
          ),
      ];
      final bad = SpreadSemanticDefinition(
        spreadId: good.projected.spreadId,
        legacyTypeName: good.projected.legacyTypeName,
        cardCount: 5,
        purposeKey: good.projected.purposeKey,
        positions: positions,
        interpretationOrder: good.projected.interpretationOrder,
        geometryHook: good.projected.geometryHook,
        lengthBand: good.projected.lengthBand,
      );
      final r = SignatureProjectionValidation.validate(withProjected(bad));
      expect(
        r.violations,
        contains(SignatureProjectionViolation.wrongTemporalOrientation),
      );
    });

    test('wrong geometry projection', () {
      final bad = SpreadSemanticDefinition(
        spreadId: good.projected.spreadId,
        legacyTypeName: good.projected.legacyTypeName,
        cardCount: 5,
        purposeKey: good.projected.purposeKey,
        positions: good.projected.positions,
        interpretationOrder: good.projected.interpretationOrder,
        geometryHook: NarrativeGeometryHook.celticCross,
        lengthBand: good.projected.lengthBand,
      );
      final r = SignatureProjectionValidation.validate(withProjected(bad));
      expect(r.violations, contains(SignatureProjectionViolation.crossroadsGeometry));
    });

    test('wrong legacyTypeName', () {
      final bad = SpreadSemanticDefinition(
        spreadId: good.projected.spreadId,
        legacyTypeName: 'fiveCard',
        cardCount: 5,
        purposeKey: good.projected.purposeKey,
        positions: good.projected.positions,
        interpretationOrder: good.projected.interpretationOrder,
        geometryHook: good.projected.geometryHook,
        lengthBand: good.projected.lengthBand,
      );
      final r = SignatureProjectionValidation.validate(withProjected(bad));
      expect(r.violations, contains(SignatureProjectionViolation.crossroadsLegacyType));
    });

    test('incorrect relation projection count', () {
      final edges = const [
        SignatureSpreadEdge(
          fromPositionKey: 'option_a',
          toPositionKey: 'option_b',
          directed: true,
          edgeKind: PositionEdgeKind.opposition,
        ),
        SignatureSpreadEdge(
          fromPositionKey: 'tension',
          toPositionKey: 'option_a',
          directed: true,
          edgeKind: PositionEdgeKind.pressure,
        ),
        SignatureSpreadEdge(
          fromPositionKey: 'tension',
          toPositionKey: 'option_b',
          directed: true,
          edgeKind: PositionEdgeKind.pressure,
        ),
        SignatureSpreadEdge(
          fromPositionKey: 'counsel',
          toPositionKey: 'direction',
          directed: true,
          edgeKind: PositionEdgeKind.supportive,
        ),
      ];
      final r = SignatureProjectionValidation.validate(withEdges(edges));
      expect(
        r.violations,
        contains(SignatureProjectionViolation.crossroadsRelationRowCount),
      );
    });

    test('source/projected role mismatch', () {
      final positions = [
        for (final p in good.projected.positions)
          SpreadPositionSemantic(
            positionKey: p.positionKey,
            index: p.index,
            role: p.positionKey == 'tension' ? PositionRole.support : p.role,
            guidingQuestionKey: p.guidingQuestionKey,
            temporal: p.temporal,
            relationToOtherSlots: p.relationToOtherSlots,
            weight: p.weight,
            displayLabelKey: p.displayLabelKey,
          ),
      ];
      final bad = SpreadSemanticDefinition(
        spreadId: good.projected.spreadId,
        legacyTypeName: good.projected.legacyTypeName,
        cardCount: 5,
        purposeKey: good.projected.purposeKey,
        positions: positions,
        interpretationOrder: good.projected.interpretationOrder,
        geometryHook: good.projected.geometryHook,
        lengthBand: good.projected.lengthBand,
      );
      final r = SignatureProjectionValidation.validate(withProjected(bad));
      expect(r.violations, contains(SignatureProjectionViolation.positionRoleMismatch));
    });

    test('source/projected key mismatch', () {
      final positions = [
        for (final p in good.projected.positions)
          SpreadPositionSemantic(
            positionKey: p.positionKey == 'tension' ? 'pressure' : p.positionKey,
            index: p.index,
            role: p.role,
            guidingQuestionKey: p.guidingQuestionKey,
            temporal: p.temporal,
            relationToOtherSlots: p.relationToOtherSlots,
            weight: p.weight,
            displayLabelKey: p.displayLabelKey,
          ),
      ];
      final bad = SpreadSemanticDefinition(
        spreadId: good.projected.spreadId,
        legacyTypeName: good.projected.legacyTypeName,
        cardCount: 5,
        purposeKey: good.projected.purposeKey,
        positions: positions,
        interpretationOrder: good.projected.interpretationOrder,
        geometryHook: good.projected.geometryHook,
        lengthBand: good.projected.lengthBand,
      );
      final r = SignatureProjectionValidation.validate(withProjected(bad));
      expect(r.violations, contains(SignatureProjectionViolation.positionKeyMismatch));
    });

    test('source/projected order mismatch', () {
      final bad = SpreadSemanticDefinition(
        spreadId: good.projected.spreadId,
        legacyTypeName: good.projected.legacyTypeName,
        cardCount: 5,
        purposeKey: good.projected.purposeKey,
        positions: good.projected.positions,
        interpretationOrder: const [4, 3, 2, 1, 0],
        geometryHook: good.projected.geometryHook,
        lengthBand: good.projected.lengthBand,
      );
      final r = SignatureProjectionValidation.validate(withProjected(bad));
      expect(
        r.violations,
        contains(SignatureProjectionViolation.interpretationOrderMismatch),
      );
    });
  });
}
