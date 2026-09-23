/// Authoritative §17.4 edge rows + projection (Phase 3D.1A).
library;

import 'narrative_spread_semantics.dart';

/// Frozen 29 authoritative classical edges (Phase 3D.0.1).
const kAuthoritativePositionEdges = <AuthoritativePositionEdge>[
  // threeCard (3 directed)
  AuthoritativePositionEdge(
    legacyTypeName: 'threeCard',
    fromPositionKey: 'past',
    toPositionKey: 'present',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'threeCard',
    fromPositionKey: 'present',
    toPositionKey: 'future',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'threeCard',
    fromPositionKey: 'past',
    toPositionKey: 'future',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  // fiveCard (2 directed, 4 undirected)
  AuthoritativePositionEdge(
    legacyTypeName: 'fiveCard',
    fromPositionKey: 'situation',
    toPositionKey: 'direction',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'fiveCard',
    fromPositionKey: 'situation',
    toPositionKey: 'hidden_influence',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'fiveCard',
    fromPositionKey: 'situation',
    toPositionKey: 'challenge',
    directed: false,
    edgeKind: PositionEdgeKind.opposition,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'fiveCard',
    fromPositionKey: 'challenge',
    toPositionKey: 'strength',
    directed: false,
    edgeKind: PositionEdgeKind.supportive,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'fiveCard',
    fromPositionKey: 'strength',
    toPositionKey: 'direction',
    directed: true,
    edgeKind: PositionEdgeKind.supportive,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'fiveCard',
    fromPositionKey: 'hidden_influence',
    toPositionKey: 'challenge',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  // sevenCard (2 directed, 6 undirected)
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'question',
    toPositionKey: 'current_energy',
    directed: false,
    edgeKind: PositionEdgeKind.mirror,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'current_energy',
    toPositionKey: 'obstacle',
    directed: false,
    edgeKind: PositionEdgeKind.opposition,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'obstacle',
    toPositionKey: 'what_helps',
    directed: false,
    edgeKind: PositionEdgeKind.supportive,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'what_to_avoid',
    toPositionKey: 'direction',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'hidden_factor',
    toPositionKey: 'current_energy',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'question',
    toPositionKey: 'direction',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'what_helps',
    toPositionKey: 'direction',
    directed: true,
    edgeKind: PositionEdgeKind.supportive,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'sevenCard',
    fromPositionKey: 'obstacle',
    toPositionKey: 'what_to_avoid',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  // celticCross (6 directed, 6 undirected)
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'distant_past',
    toPositionKey: 'recent_past',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'recent_past',
    toPositionKey: 'present',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'distant_past',
    toPositionKey: 'present',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'present',
    toPositionKey: 'near_future',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'present',
    toPositionKey: 'challenge',
    directed: false,
    edgeKind: PositionEdgeKind.opposition,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'self',
    toPositionKey: 'environment',
    directed: false,
    edgeKind: PositionEdgeKind.mirror,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'present',
    toPositionKey: 'self',
    directed: false,
    edgeKind: PositionEdgeKind.mirror,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'challenge',
    toPositionKey: 'outcome',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'hopes',
    toPositionKey: 'outcome',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'crown',
    toPositionKey: 'outcome',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'challenge',
    toPositionKey: 'self',
    directed: false,
    edgeKind: PositionEdgeKind.pressure,
  ),
  AuthoritativePositionEdge(
    legacyTypeName: 'celticCross',
    fromPositionKey: 'near_future',
    toPositionKey: 'outcome',
    directed: true,
    edgeKind: PositionEdgeKind.temporal,
  ),
];

/// Projects authoritative edges onto a position's relation list.
List<PositionRelationEdge> projectedRelationsFor({
  required String legacyTypeName,
  required String positionKey,
}) {
  final out = <PositionRelationEdge>[];
  for (final e in kAuthoritativePositionEdges) {
    if (e.legacyTypeName != legacyTypeName) continue;
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
