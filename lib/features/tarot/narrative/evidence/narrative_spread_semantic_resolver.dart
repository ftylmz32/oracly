/// Phase 6A — spread semantic resolver seam (Classical default).
library;

import '../../domain/models/tarot_spread.dart';
import 'narrative_classical_spread_catalog.dart';
import 'narrative_spread_semantics.dart';

/// Resolves runtime [TarotSpreadType] into a [SpreadSemanticDefinition].
abstract interface class NarrativeSpreadSemanticResolver {
  SpreadSemanticDefinition resolve(TarotSpreadType type);
}

/// Default Classical-only resolver — preserves pre-6A behavior.
final class ClassicalSpreadSemanticResolver
    implements NarrativeSpreadSemanticResolver {
  const ClassicalSpreadSemanticResolver();

  @override
  SpreadSemanticDefinition resolve(TarotSpreadType type) {
    return ClassicalSpreadSemantics.byLegacyTypeName(type.name);
  }
}
