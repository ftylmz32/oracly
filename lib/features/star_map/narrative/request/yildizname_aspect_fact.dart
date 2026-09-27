/// Provider-safe aspect fact — only Phase 4 deterministic aspects.
library;

final class YildiznameAspectFact {
  const YildiznameAspectFact({
    required this.factRef,
    required this.bodyA,
    required this.bodyB,
    required this.type,
    required this.orb,
    required this.certainty,
  });

  final String factRef;
  final String bodyA;
  final String bodyB;
  final String type;
  final double orb;

  /// Authoritative `NatalAspect.certainty` — the frozen wire contract
  /// requires it on every FULL aspect (only `exact` is accepted).
  final String certainty;

  Map<String, dynamic> toProviderJson() => {
        'factRef': factRef,
        'bodyA': bodyA,
        'bodyB': bodyB,
        'type': type,
        'orb': orb,
        'certainty': certainty,
      };
}
