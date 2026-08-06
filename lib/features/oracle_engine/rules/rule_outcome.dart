/// OR-1140 — Declarative rule outcome payload.
library;

class RuleOutcome {
  const RuleOutcome({
    required this.sectionKey,
    required this.titleKey,
    required this.contentKey,
    this.weight = 1,
    this.tags = const [],
  });

  final String sectionKey;
  final String titleKey;
  final String contentKey;
  final int weight;
  final List<String> tags;

  factory RuleOutcome.fromMap(Map<String, dynamic> map) {
    return RuleOutcome(
      sectionKey: map['sectionKey'] as String,
      titleKey: map['titleKey'] as String,
      contentKey: map['contentKey'] as String,
      weight: map['weight'] as int? ?? 1,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
