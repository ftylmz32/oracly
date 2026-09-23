/// Phase 5B — immutable signature → Phase 3 semantic projection result.
library;

import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_edge.dart';

class SignatureSpreadSemanticProjection {
  SignatureSpreadSemanticProjection({
    required this.source,
    required this.projected,
    required List<SignatureSpreadEdge> edges,
  }) : edges = List<SignatureSpreadEdge>.unmodifiable(edges);

  final SignatureSpreadDefinition source;
  final SpreadSemanticDefinition projected;
  final List<SignatureSpreadEdge> edges;

  int get projectedRelationRowCount {
    var n = 0;
    for (final e in edges) {
      n += e.directed ? 1 : 2;
    }
    return n;
  }
}
