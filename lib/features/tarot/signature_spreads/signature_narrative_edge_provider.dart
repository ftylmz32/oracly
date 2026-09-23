/// Phase 6A — Signature-only position edge provider adapter.
library;

import '../domain/models/tarot_spread.dart';
import '../narrative/evidence/narrative_position_edge_provider.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_narrative_spread_resolver.dart';
import 'signature_spread_crossroads_edges.dart';

/// Adapts frozen Signature edges into Phase 3 [AuthoritativePositionEdge] shape.
///
/// Rejects Classical / spoofed definitions fail-closed (Phase 6A.1).
final class SignatureNarrativeEdgeProvider
    implements NarrativePositionEdgeProvider {
  const SignatureNarrativeEdgeProvider();

  @override
  List<AuthoritativePositionEdge> edgesFor(SpreadSemanticDefinition spread) {
    final expected = const SignatureNarrativeSpreadResolver().resolve(
      TarotSpreadType.crossroads,
    );
    if (spread.spreadId != expected.spreadId ||
        spread.legacyTypeName != expected.legacyTypeName ||
        spread.cardCount != expected.cardCount) {
      throw ArgumentError.value(
        spread.spreadId,
        'spread',
        'SignatureNarrativeEdgeProvider received a non-Signature or mismatched '
            'spread',
      );
    }
    final expectedKeys = {
      for (final p in expected.positions) p.positionKey,
    };
    final actualKeys = {
      for (final p in spread.positions) p.positionKey,
    };
    if (!_sameKeys(expectedKeys, actualKeys)) {
      throw ArgumentError.value(
        spread.spreadId,
        'spread',
        'SignatureNarrativeEdgeProvider position keys mismatch projection',
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

  static bool _sameKeys(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final k in a) {
      if (!b.contains(k)) return false;
    }
    return true;
  }
}
