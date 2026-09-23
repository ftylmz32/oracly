/// Phase 5B — Crossroads-specific projection checks.
library;

import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_crossroads_edges.dart';
import 'signature_spread_edge.dart';
import 'signature_spread_projection_validation.dart';
import 'signature_spread_semantic_projection.dart';

abstract final class SignatureProjectionCrossroadsChecks {
  SignatureProjectionCrossroadsChecks._();

  static void apply(
    SpreadSemanticDefinition projected,
    List<SignatureSpreadEdge> edges,
    SignatureSpreadSemanticProjection projection,
    List<SignatureProjectionViolation> out,
  ) {
    if (edges.length != 4) {
      out.add(SignatureProjectionViolation.crossroadsEdgeCount);
    }
    if (projection.projectedRelationRowCount != 7) {
      out.add(SignatureProjectionViolation.crossroadsRelationRowCount);
    }
    if (projected.legacyTypeName != 'crossroads') {
      out.add(SignatureProjectionViolation.crossroadsLegacyType);
    }
    if (projected.geometryHook != NarrativeGeometryHook.linearRow) {
      out.add(SignatureProjectionViolation.crossroadsGeometry);
    }
    if (projected.lengthBand != NarrativeLengthBand.full) {
      out.add(SignatureProjectionViolation.crossroadsLength);
    }
    const expected = {
      'option_a': TemporalOrientation.atemporal,
      'option_b': TemporalOrientation.atemporal,
      'tension': TemporalOrientation.atemporal,
      'counsel': TemporalOrientation.atemporal,
      'direction': TemporalOrientation.future,
    };
    for (final p in projected.positions) {
      if (expected[p.positionKey] != p.temporal) {
        out.add(SignatureProjectionViolation.wrongTemporalOrientation);
      }
    }
    if (!_edgesMatchLocked(edges)) {
      out.add(SignatureProjectionViolation.crossroadsEdgeCount);
    }
  }

  static bool _edgesMatchLocked(List<SignatureSpreadEdge> edges) {
    if (edges.length != kSignatureCrossroadsEdges.length) return false;
    for (var i = 0; i < edges.length; i++) {
      final a = edges[i];
      final b = kSignatureCrossroadsEdges[i];
      if (a.fromPositionKey != b.fromPositionKey ||
          a.toPositionKey != b.toPositionKey ||
          a.directed != b.directed ||
          a.edgeKind != b.edgeKind) {
        return false;
      }
    }
    return true;
  }
}
