/// Phase 6A — Signature resolver + edge provider + lower-level Crossroads pairing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_pairing.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_relationship_context.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_edge_provider.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_spread_resolver.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads_edges.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projector.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_runtime_bridge.dart';

import '../narrative_evidence/narrative_relationship_test_support.dart';
import 'signature_projection_test_support.dart';

void main() {
  const resolver = SignatureNarrativeSpreadResolver();
  const edgeProvider = SignatureNarrativeEdgeProvider();

  group('SignatureNarrativeSpreadResolver', () {
    test('crossroads matches Phase 5 projected semantics', () {
      final projected = resolver.resolve(TarotSpreadType.crossroads);
      final def =
          SignatureSpreadRuntimeBridge.definitionFor(TarotSpreadType.crossroads)!;
      final fromProjector = SignatureSpreadProjector.project(def).projected;
      expectSemanticsEqual(projected, fromProjector);
      expect(projected.spreadId, 'signature.crossroads');
      expect(projected.legacyTypeName, 'crossroads');
      expect(projected.cardCount, 5);
      expect(projected.geometryHook, NarrativeGeometryHook.linearRow);
      expect(projected.lengthBand, NarrativeLengthBand.full);
    });

    test('classical types fail — no Classical fallback', () {
      for (final type in [
        TarotSpreadType.single,
        TarotSpreadType.threeCard,
        TarotSpreadType.fiveCard,
        TarotSpreadType.sevenCard,
        TarotSpreadType.celticCross,
      ]) {
        expect(
          () => resolver.resolve(type),
          throwsA(isA<ArgumentError>()),
          reason: type.name,
        );
      }
    });
  });

  group('SignatureNarrativeEdgeProvider', () {
    test('exactly four Crossroads edges, unmodifiable + deterministic', () {
      final spread = resolver.resolve(TarotSpreadType.crossroads);
      final edges = edgeProvider.edgesFor(spread);
      expect(edges, hasLength(4));
      expect(kSignatureCrossroadsEdges, hasLength(4));
      for (var i = 0; i < 4; i++) {
        final src = kSignatureCrossroadsEdges[i];
        expect(edges[i].fromPositionKey, src.fromPositionKey);
        expect(edges[i].toPositionKey, src.toPositionKey);
        expect(edges[i].directed, src.directed);
        expect(edges[i].edgeKind, src.edgeKind);
        expect(edges[i].legacyTypeName, 'crossroads');
      }
      final again = edgeProvider.edgesFor(spread);
      for (var i = 0; i < 4; i++) {
        expect(again[i].fromPositionKey, edges[i].fromPositionKey);
      }
      expect(
        () => edges.add(edges.first),
        throwsUnsupportedError,
      );

      final def =
          SignatureSpreadRuntimeBridge.definitionFor(TarotSpreadType.crossroads)!;
      final proj = SignatureSpreadProjector.project(def);
      expect(proj.edges, hasLength(4));
      expect(proj.projectedRelationRowCount, 7);
    });

    test('classical spreads fail explicitly', () {
      expect(
        () => edgeProvider.edgesFor(threeCard()),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('lower-level Crossroads pairing via Signature provider', () {
    test('four edges + null no-edge pair', () {
      final spread = resolver.resolve(TarotSpreadType.crossroads);
      NarrativePositionPairMatch pair(String a, int ai, String b, int bi) {
        return NarrativeRelationshipPairing.matchPositions(
          spread: spread,
          left: ctx(id: 'L', positionKey: a, positionIndex: ai),
          right: ctx(id: 'R', positionKey: b, positionIndex: bi),
          edgeProvider: edgeProvider,
        );
      }

      final ab = pair('option_a', 0, 'option_b', 1);
      expect(ab.edgeKind, PositionEdgeKind.opposition);
      expect(ab.directed, isFalse);

      final ta = pair('tension', 2, 'option_a', 0);
      expect(ta.edgeKind, PositionEdgeKind.pressure);
      expect(ta.directed, isFalse);

      final tb = pair('tension', 2, 'option_b', 1);
      expect(tb.edgeKind, PositionEdgeKind.pressure);
      expect(tb.directed, isFalse);

      final cd = pair('counsel', 3, 'direction', 4);
      expect(cd.edgeKind, PositionEdgeKind.supportive);
      expect(cd.directed, isTrue);
      expect(cd.fromPositionKey, 'counsel');
      expect(cd.toPositionKey, 'direction');

      // Reversed caller order — authoritative direction preserved
      final dc = pair('direction', 4, 'counsel', 3);
      expect(dc.fromPositionKey, 'counsel');
      expect(dc.toPositionKey, 'direction');
      expect(dc.directed, isTrue);

      final none = pair('option_a', 0, 'counsel', 3);
      expect(none.edgeKind, isNull);
    });
  });
}
