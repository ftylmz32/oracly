/// Phase 6A — position edge provider seam (Classical default).
library;

import 'narrative_position_edges.dart';
import 'narrative_spread_semantics.dart';

/// Supplies authoritative position edges for a resolved spread.
abstract interface class NarrativePositionEdgeProvider {
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread);
}

/// Default Classical provider — filters frozen [kAuthoritativePositionEdges].
final class ClassicalPositionEdgeProvider
    implements NarrativePositionEdgeProvider {
  const ClassicalPositionEdgeProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) {
    return List<AuthoritativePositionEdge>.unmodifiable([
      for (final e in kAuthoritativePositionEdges)
        if (e.legacyTypeName == spread.legacyTypeName) e,
    ]);
  }
}
