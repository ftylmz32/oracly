/// Phase 5B — classical parity + Crossroads projection contracts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads_edges.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_enums.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projection_validation.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projector.dart';

import 'signature_projection_test_support.dart';

void main() {
  group('SignatureSpreadProjector classical parity', () {
    test('Quick Insight == classical.single', () {
      final p = SignatureSpreadProjector.project(
        SignatureSpreadCatalog.launch[0],
      );
      expectSemanticsEqual(
        p.projected,
        ClassicalSpreadSemantics.bySpreadId('classical.single'),
      );
      expect(p.edges, isEmpty);
      expect(p.projectedRelationRowCount, 0);
      expect(SignatureProjectionValidation.validate(p).isValid, isTrue);
    });

    test('Timeline == classical.threeCard', () {
      final p = SignatureSpreadProjector.project(
        SignatureSpreadCatalog.launch[1],
      );
      expectSemanticsEqual(
        p.projected,
        ClassicalSpreadSemantics.bySpreadId('classical.threeCard'),
      );
      expect(p.edges, hasLength(3));
      expect(p.projectedRelationRowCount, 3);
      expect(SignatureProjectionValidation.validate(p).isValid, isTrue);
    });

    test('Deep Field == classical.fiveCard', () {
      final p = SignatureSpreadProjector.project(
        SignatureSpreadCatalog.launch[2],
      );
      expectSemanticsEqual(
        p.projected,
        ClassicalSpreadSemantics.bySpreadId('classical.fiveCard'),
      );
      expect(p.edges, hasLength(6));
      expect(p.projectedRelationRowCount, 10);
      expect(SignatureProjectionValidation.validate(p).isValid, isTrue);
    });
  });

  group('Crossroads projection', () {
    test('exact Phase 5 structural locks', () {
      final src = SignatureSpreadCatalog.launch[3];
      final p = SignatureSpreadProjector.project(src);
      expect(p.projected.spreadId, 'signature.crossroads');
      expect(p.projected.legacyTypeName, 'crossroads');
      expect(p.projected.cardCount, 5);
      expect(p.projected.purposeKey, src.purposeKey);
      expect(p.projected.geometryHook, NarrativeGeometryHook.linearRow);
      expect(p.projected.lengthBand, NarrativeLengthBand.full);
      expect(src.signatureGeometryHook, SignatureGeometryHook.fiveDecision);
      expect(p.projected.interpretationOrder, [0, 1, 2, 3, 4]);
      expect(
        p.projected.positions.map((x) => x.role).toList(),
        [
          PositionRole.direction,
          PositionRole.direction,
          PositionRole.challenge,
          PositionRole.support,
          PositionRole.direction,
        ],
      );
      expect(
        p.projected.positions.map((x) => x.temporal).toList(),
        [
          TemporalOrientation.atemporal,
          TemporalOrientation.atemporal,
          TemporalOrientation.atemporal,
          TemporalOrientation.atemporal,
          TemporalOrientation.future,
        ],
      );
      expect(p.edges, hasLength(4));
      expect(p.projectedRelationRowCount, 7);
      expect(signatureProjectedRelationRowCount(p.edges), 7);
      expect(_hasEdge(p, 'option_a', 'option_b', false, PositionEdgeKind.opposition), isTrue);
      expect(_hasEdge(p, 'tension', 'option_a', false, PositionEdgeKind.pressure), isTrue);
      expect(_hasEdge(p, 'tension', 'option_b', false, PositionEdgeKind.pressure), isTrue);
      expect(_hasEdge(p, 'counsel', 'direction', true, PositionEdgeKind.supportive), isTrue);
      expect(SignatureProjectionValidation.validate(p).isValid, isTrue);
    });
  });
}

bool _hasEdge(
  dynamic p,
  String from,
  String to,
  bool directed,
  PositionEdgeKind kind,
) {
  for (final e in p.edges) {
    if (e.fromPositionKey == from &&
        e.toPositionKey == to &&
        e.directed == directed &&
        e.edgeKind == kind) {
      return true;
    }
  }
  return false;
}
