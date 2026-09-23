/// Phase 5B — locked Crossroads edge set (exactly 4). Not Phase 3 global table.
library;

import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_edge.dart';

/// Canonical Crossroads edges — immutable · count locked at 4.
const kSignatureCrossroadsEdges = <SignatureSpreadEdge>[
  SignatureSpreadEdge(
    fromPositionKey: 'option_a',
    toPositionKey: 'option_b',
    directed: false,
    edgeKind: PositionEdgeKind.opposition,
  ),
  SignatureSpreadEdge(
    fromPositionKey: 'tension',
    toPositionKey: 'option_a',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  SignatureSpreadEdge(
    fromPositionKey: 'tension',
    toPositionKey: 'option_b',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  SignatureSpreadEdge(
    fromPositionKey: 'counsel',
    toPositionKey: 'direction',
    directed: true,
    edgeKind: PositionEdgeKind.supportive,
  ),
];

/// Projects Phase 5 edges onto a position (mirrors frozen projection rules).
List<PositionRelationEdge> signatureProjectedRelationsFor({
  required List<SignatureSpreadEdge> edges,
  required String positionKey,
}) {
  final out = <PositionRelationEdge>[];
  for (final e in edges) {
    if (e.fromPositionKey == positionKey) {
      out.add(
        PositionRelationEdge(
          otherPositionKey: e.toPositionKey,
          edgeKind: e.edgeKind,
          directed: e.directed,
        ),
      );
    } else if (!e.directed && e.toPositionKey == positionKey) {
      out.add(
        PositionRelationEdge(
          otherPositionKey: e.fromPositionKey,
          edgeKind: e.edgeKind,
          directed: false,
        ),
      );
    }
  }
  return List<PositionRelationEdge>.unmodifiable(out);
}

int signatureProjectedRelationRowCount(List<SignatureSpreadEdge> edges) {
  var n = 0;
  for (final e in edges) {
    n += e.directed ? 1 : 2;
  }
  return n;
}
