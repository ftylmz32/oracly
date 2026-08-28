/// SPRINT-001 — Reflective insight (post-understanding).
library;

enum DreamInsightKind {
  summary,
  mainInterpretation,
  symbols,
  emotionalMeaning,
  themes,
  practicalTakeaway,
  personalConnection,
  closingQuestion,
  reflection,
  possibility,
  closingTakeaway,
}

class DreamInsight {
  const DreamInsight({
    required this.kind,
    required this.body,
    this.title,
  });

  final DreamInsightKind kind;
  final String? title;
  final String body;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'body': body,
        if (title != null) 'title': title,
      };

  factory DreamInsight.fromJson(Map<String, dynamic> json) {
    return DreamInsight(
      kind: DreamInsightKind.values.byName(json['kind'] as String),
      title: json['title'] as String?,
      body: json['body'] as String,
    );
  }
}
