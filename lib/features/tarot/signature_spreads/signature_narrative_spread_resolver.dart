/// Phase 6A — Signature-only spread semantic resolver adapter.
library;

import '../domain/models/tarot_spread.dart';
import '../narrative/evidence/narrative_spread_semantic_resolver.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_projector.dart';
import 'signature_spread_runtime_bridge.dart';

/// Resolves Signature runtime types only — never Classical fallback.
final class SignatureNarrativeSpreadResolver
    implements NarrativeSpreadSemanticResolver {
  const SignatureNarrativeSpreadResolver();

  @override
  SpreadSemanticDefinition resolve(TarotSpreadType type) {
    if (type != TarotSpreadType.crossroads) {
      throw ArgumentError.value(
        type,
        'type',
        'SignatureNarrativeSpreadResolver supports crossroads only',
      );
    }
    final definition = SignatureSpreadRuntimeBridge.definitionFor(type);
    if (definition == null) {
      throw StateError('Crossroads signature definition missing');
    }
    return SignatureSpreadProjector.project(definition).projected;
  }
}
