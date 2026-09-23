/// Phase 5B — Phase 5-owned immutable spread edge (not Phase 3 table).
library;

import '../narrative/evidence/narrative_spread_semantics.dart';

class SignatureSpreadEdge {
  const SignatureSpreadEdge({
    required this.fromPositionKey,
    required this.toPositionKey,
    required this.directed,
    required this.edgeKind,
  });

  final String fromPositionKey;
  final String toPositionKey;
  final bool directed;
  final PositionEdgeKind edgeKind;
}
