/// OR-438 — Module lifecycle without changing current UX.
library;

/// How a module appears in discovery surfaces (home, settings, deep links).
enum OraclyFeatureAvailability {
  /// Fully integrated — navigable today.
  live,

  /// Hub / preview screen — partial experience.
  preview,

  /// Registered for routing and architecture only — not yet surfaced.
  reserved,
}
