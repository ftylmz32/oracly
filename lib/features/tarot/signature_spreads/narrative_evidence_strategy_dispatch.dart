/// Phase 6G — Classical vs Signature Narrative evidence strategy dispatch.
library;

import '../domain/models/tarot_spread.dart';
import '../narrative/evidence/narrative_position_edge_provider.dart';
import '../narrative/evidence/narrative_spread_semantic_resolver.dart';
import 'signature_narrative_edge_provider.dart';
import 'signature_narrative_spread_resolver.dart';

/// Immutable resolver + edge-provider pair for one evidence build.
class NarrativeEvidenceStrategy {
  const NarrativeEvidenceStrategy({
    required this.resolver,
    required this.edgeProvider,
  });

  final NarrativeSpreadSemanticResolver resolver;
  final NarrativePositionEdgeProvider edgeProvider;
}

/// Explicit strategy selection — never silently coerces Crossroads → Classical.
abstract final class NarrativeEvidenceStrategyDispatch {
  NarrativeEvidenceStrategyDispatch._();

  static const classical = NarrativeEvidenceStrategy(
    resolver: ClassicalSpreadSemanticResolver(),
    edgeProvider: ClassicalPositionEdgeProvider(),
  );

  static const signatureCrossroads = NarrativeEvidenceStrategy(
    resolver: SignatureNarrativeSpreadResolver(),
    edgeProvider: SignatureNarrativeEdgeProvider(),
  );

  /// Crossroads → Signature pair · all other types → Classical pair.
  static NarrativeEvidenceStrategy forSpread(TarotSpreadType type) {
    if (type == TarotSpreadType.crossroads) return signatureCrossroads;
    return classical;
  }
}
