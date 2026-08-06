/// OR-439 — Lightweight personal themes derived from reading history.
library;

/// Recurring life themes — observations, not predictions.
enum PersonalInsightTheme {
  love('love', 'Aşk'),
  career('career', 'Kariyer'),
  personalGrowth('growth', 'Kişisel Gelişim'),
  change('change', 'Değişim'),
  courage('courage', 'Cesaret'),
  patience('patience', 'Sabır'),
  newBeginnings('beginnings', 'Yeni Başlangıçlar'),
  reflection('reflection', 'Yansıma');

  const PersonalInsightTheme(this.id, this.label);

  final String id;
  final String label;

  static PersonalInsightTheme? fromId(String id) {
    for (final theme in values) {
      if (theme.id == id) return theme;
    }
    return null;
  }

  /// Stored in [RitualJournalMetadata.tags] as `insight:<id>`.
  String get storageTag => 'insight:$id';
}
