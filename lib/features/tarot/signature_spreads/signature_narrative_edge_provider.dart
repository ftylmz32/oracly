/// Phase 6A — Signature-only position edge provider adapter.
library;

import '../narrative/evidence/narrative_position_edge_provider.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_crossroads_edges.dart';

/// Adapts frozen Signature edges into Phase 3 [AuthoritativePositionEdge] shape.
final class SignatureNarrativeEdgeProvider
    implements NarrativePositionEdgeProvider {
  const SignatureNarrativeEdgeProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) {
    if (spread.spreadId != 'signature.crossroads') {
      throw ArgumentError.value(
        spread.spreadId,
        'spread.spreadId',
        'SignatureNarrativeEdgeProvider supports signature.crossroads only',
      );
    }
    return List<AuthoritativePositionEdge>.unmodifiable([
      for (final e in kSignatureCrossroadsEdges)
        AuthoritativePositionEdge(
          legacyTypeName: spread.legacyTypeName,
          fromPositionKey: e.fromPositionKey,
          toPositionKey: e.toPositionKey,
          directed: e.directed,
          edgeKind: e.edgeKind,
        ),
    ]);
  }
}
