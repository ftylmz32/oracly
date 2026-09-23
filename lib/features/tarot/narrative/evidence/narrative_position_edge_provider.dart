/// Phase 6A — position edge provider seam (Classical default).
library;

import 'narrative_classical_spread_catalog.dart';
import 'narrative_position_edges.dart';
import 'narrative_spread_semantics.dart';

/// Supplies authoritative position edges for a resolved spread.
abstract interface class NarrativePositionEdgeProvider {
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread);
}

/// Default Classical provider — filters frozen [kAuthoritativePositionEdges].
///
/// Rejects non-Classical / mismatched spreads fail-closed (Phase 6A.1).
/// Valid classical.single still returns an empty edge list.
final class ClassicalPositionEdgeProvider
    implements NarrativePositionEdgeProvider {
  const ClassicalPositionEdgeProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) {
    final authoritative = ClassicalSpreadSemantics.byLegacyTypeName(
      spread.legacyTypeName,
    );
    if (authoritative.spreadId != spread.spreadId ||
        authoritative.cardCount != spread.cardCount) {
      throw ArgumentError.value(
        spread.spreadId,
        'spread',
        'ClassicalPositionEdgeProvider received a non-Classical or mismatched '
            'spread',
      );
    }
    return List<AuthoritativePositionEdge>.unmodifiable([
      for (final e in kAuthoritativePositionEdges)
        if (e.legacyTypeName == spread.legacyTypeName) e,
    ]);
  }
}
