/// SPRINT-003 — Memory visibility and consent.
library;

enum MemoryPermission {
  /// User explicitly saved — companion may reference.
  saved,

  /// Visible this session only — never persisted.
  ephemeral,

  /// User declined — never store or reference.
  denied,
}
