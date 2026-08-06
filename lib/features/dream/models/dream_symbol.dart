/// SPRINT-001 — Observed dream symbol (understanding phase).
library;

enum DreamSymbolKind {
  object,
  animal,
  place,
  color,
  action,
  person,
  nature,
  other,
}

class DreamSymbol {
  const DreamSymbol({
    required this.token,
    required this.label,
    required this.kind,
    this.confidence = 1.0,
    this.observedContext,
  });

  final String token;
  final String label;
  final DreamSymbolKind kind;
  final double confidence;
  final String? observedContext;

  Map<String, dynamic> toJson() => {
        'token': token,
        'label': label,
        'kind': kind.name,
        'confidence': confidence,
        if (observedContext != null) 'observedContext': observedContext,
      };

  factory DreamSymbol.fromJson(Map<String, dynamic> json) {
    return DreamSymbol(
      token: json['token'] as String,
      label: json['label'] as String,
      kind: DreamSymbolKind.values.byName(json['kind'] as String),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      observedContext: json['observedContext'] as String?,
    );
  }
}
