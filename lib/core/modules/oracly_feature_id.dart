/// OR-438 — Canonical feature identifiers across UI, engines, and content.
library;

/// Every Oracly experience module — live, preview, and reserved future slots.
enum OraclyFeatureId {
  home,
  tarot,
  aiChat,
  dailyEnergy,
  dream,
  astrology,
  starMap,
  readingHistory,
  personalInsights,
  memory,
  achievements,
  premium,
  profile,
  settings,
  // ── Reserved for natural extension (OR-438) ─────────────────────────────
  numerology,
  moonCalendar,
  manifestation,
}
