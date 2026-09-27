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

  /// Prior-Dream evidence (Phase 4A) — local, recomputed, never persisted.
  recurringPattern,
}

/// Who wrote a section. Records saved before sections carried a source
/// decode as [legacyUnknown] — never upgraded to [ai] after the fact.
enum DreamInsightSource {
  /// Provider text that survived the client grounding guard.
  ai,

  /// Composed on device from the user's own told facts.
  local,

  /// Persisted without source metadata; provenance cannot be claimed.
  legacyUnknown;

  static DreamInsightSource fromJson(Object? raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return legacyUnknown;
  }
}

class DreamInsight {
  const DreamInsight({
    required this.kind,
    required this.body,
    this.title,
    this.source = DreamInsightSource.legacyUnknown,
  });

  final DreamInsightKind kind;
  final String? title;
  final String body;
  final DreamInsightSource source;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'body': body,
        if (title != null) 'title': title,
        'source': source.name,
      };

  factory DreamInsight.fromJson(Map<String, dynamic> json) {
    return DreamInsight(
      kind: DreamInsightKind.values.byName(json['kind'] as String),
      title: json['title'] as String?,
      body: json['body'] as String,
      source: DreamInsightSource.fromJson(json['source']),
    );
  }
}
