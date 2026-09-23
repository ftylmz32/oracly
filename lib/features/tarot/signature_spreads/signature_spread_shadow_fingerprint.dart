/// Phase 5E — deterministic structural fingerprint (no crypto / hashCode).
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_edge.dart';
import 'signature_spread_semantic_projection.dart';
import 'signature_spread_shadow_normalized.dart';

abstract final class SignatureSpreadShadowFingerprint {
  SignatureSpreadShadowFingerprint._();

  static String compute({
    required SignatureSpreadDefinition definition,
    required SignatureSpreadSemanticProjection projection,
    required List<SignatureSpreadShadowNormalizedCard> cards,
    required QuestionKind questionKind,
  }) {
    final lines = <String>[
      'spreadId=${definition.spreadId}',
      'version=${definition.version}',
      'geometry=${definition.signatureGeometryHook.name}',
      'phase3Geometry=${projection.projected.geometryHook.name}',
      'arc=${definition.dominantArcKey}',
      'questionKind=${questionKind.name}',
      'order=${definition.interpretationOrder.join(',')}',
    ];
    for (final c in cards) {
      lines.add(
        'card=${c.positionKey}:${c.role.name}:'
        '${c.canonicalCardId}:${c.isReversed}',
      );
    }
    final edges = List<SignatureSpreadEdge>.from(projection.edges)
      ..sort(_edgeCompare);
    for (final e in edges) {
      lines.add(
        'edge=${e.fromPositionKey}>${e.toPositionKey}:'
        '${e.edgeKind.name}:${e.directed}',
      );
    }
    return lines.join('\n');
  }

  static int _edgeCompare(SignatureSpreadEdge a, SignatureSpreadEdge b) {
    final from = a.fromPositionKey.compareTo(b.fromPositionKey);
    if (from != 0) return from;
    final to = a.toPositionKey.compareTo(b.toPositionKey);
    if (to != 0) return to;
    final kind = a.edgeKind.name.compareTo(b.edgeKind.name);
    if (kind != 0) return kind;
    return (a.directed ? 1 : 0).compareTo(b.directed ? 1 : 0);
  }
}
