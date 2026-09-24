/// Phase 6B — Signature historical spread resolution (Crossroads only).
library;

import '../domain/models/tarot_spread.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_narrative_spread_resolver.dart';

/// Resolves Signature runtime types for Phase 4 history — never Classical.
///
/// Non-Signature runtime → null (data path). Crossroads → must resolve;
/// invariant/programming failures must not be swallowed (Phase 6B.1).
abstract final class SignatureHistorySpreadNormalizer {
  SignatureHistorySpreadNormalizer._();

  /// Crossroads → frozen Phase 5 projected semantics; else null.
  static SpreadSemanticDefinition? fromSpread(TarotSpreadType type) {
    if (type != TarotSpreadType.crossroads) return null;
    return const SignatureNarrativeSpreadResolver().resolve(type);
  }
}
