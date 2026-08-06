/// OR-437 — Ritual journal metadata — future-ready personal reading memory.
library;

/// Extensible journal envelope for search, favorites, stats, and AI insights.
class RitualJournalMetadata {
  const RitualJournalMetadata({
    this.emotionalKeywords = const [],
    this.personalNote,
    this.summaryExcerpt,
    this.isFavorite = false,
    this.schemaVersion = 1,
    this.tags = const [],
  });

  /// Poetic mood tags derived locally from the interpretation — not predictions.
  final List<String> emotionalKeywords;

  /// Optional private reflection written by the user.
  final String? personalNote;

  /// Short excerpt for timeline cards (full text remains in [aiSummary]).
  final String? summaryExcerpt;

  /// Reserved for future favorites filtering.
  final bool isFavorite;

  /// Reserved for future migrations.
  final int schemaVersion;

  /// Reserved for future user-defined or system tags.
  final List<String> tags;

  bool get hasPersonalNote =>
      personalNote != null && personalNote!.trim().isNotEmpty;

  RitualJournalMetadata copyWith({
    List<String>? emotionalKeywords,
    String? personalNote,
    bool clearPersonalNote = false,
    String? summaryExcerpt,
    bool? isFavorite,
    int? schemaVersion,
    List<String>? tags,
  }) {
    return RitualJournalMetadata(
      emotionalKeywords: emotionalKeywords ?? this.emotionalKeywords,
      personalNote:
          clearPersonalNote ? null : (personalNote ?? this.personalNote),
      summaryExcerpt: summaryExcerpt ?? this.summaryExcerpt,
      isFavorite: isFavorite ?? this.isFavorite,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'emotionalKeywords': emotionalKeywords,
        'personalNote': personalNote,
        'summaryExcerpt': summaryExcerpt,
        'isFavorite': isFavorite,
        'schemaVersion': schemaVersion,
        'tags': tags,
      };

  factory RitualJournalMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RitualJournalMetadata();
    return RitualJournalMetadata(
      emotionalKeywords: (json['emotionalKeywords'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      personalNote: json['personalNote'] as String?,
      summaryExcerpt: json['summaryExcerpt'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
