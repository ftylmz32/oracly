/// Position edge lookup + pair left/right normalization helpers (3D.1C).
library;

import 'narrative_position_edges.dart';
import 'narrative_relationship_context.dart';
import 'narrative_spread_semantics.dart';

abstract final class NarrativeRelationshipPairing {
  NarrativeRelationshipPairing._();

  static (NarrativeRelationshipCardContext, NarrativeRelationshipCardContext)
  normalizePair(
    NarrativeRelationshipCardContext a,
    NarrativeRelationshipCardContext b,
  ) {
    if (a.positionIndex < b.positionIndex) return (a, b);
    if (b.positionIndex < a.positionIndex) return (b, a);
    if (a.canonicalCardId.compareTo(b.canonicalCardId) <= 0) return (a, b);
    return (b, a);
  }

  static NarrativePositionPairMatch matchPositions({
    required SpreadSemanticDefinition spread,
    required NarrativeRelationshipCardContext left,
    required NarrativeRelationshipCardContext right,
  }) {
    final byKey = {for (final p in spread.positions) p.positionKey: p};
    final leftPos = byKey[left.positionKey];
    final rightPos = byKey[right.positionKey];
    if (leftPos == null || rightPos == null) {
      throw ArgumentError('unknown position key in spread');
    }

    AuthoritativePositionEdge? edge;
    for (final e in kAuthoritativePositionEdges) {
      if (e.legacyTypeName != spread.legacyTypeName) continue;
      final ab =
          e.fromPositionKey == left.positionKey &&
          e.toPositionKey == right.positionKey;
      final ba =
          e.fromPositionKey == right.positionKey &&
          e.toPositionKey == left.positionKey;
      if (!ab && !ba) continue;
      if (edge != null) {
        throw StateError(
          'multiple edges for ${left.positionKey}/${right.positionKey}',
        );
      }
      edge = e;
    }

    if (edge == null) {
      return NarrativePositionPairMatch(
        edgeKind: null,
        directed: false,
        fromPositionKey: null,
        toPositionKey: null,
        leftRole: leftPos.role,
        rightRole: rightPos.role,
      );
    }

    return NarrativePositionPairMatch(
      edgeKind: edge.edgeKind,
      directed: edge.directed,
      fromPositionKey: edge.fromPositionKey,
      toPositionKey: edge.toPositionKey,
      leftRole: leftPos.role,
      rightRole: rightPos.role,
    );
  }
}
