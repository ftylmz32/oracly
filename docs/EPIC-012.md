# EPIC-012 — Personal Journey

**Status:** Canonical · Long-term companion foundation — memory over statistics  
**Version:** 1.0  
**Perspective:** Expand ORACLY from an experience into a long-term companion  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → … → [EPIC-011 Daily Ritual](./EPIC-011.md) → **EPIC-012 Personal Journey** → [EPIC-013 Reflective Intelligence](./EPIC-013.md) → [AI Agent Guide](./AI_AGENT_GUIDE.md)

---

> *Users should eventually feel: "This app grows with me."*

Do not redesign existing screens. Do not change navigation. Build upon the existing architecture.

---

## Mission

Introduce the foundation of a personal journey.

Users should begin to feel that ORACLY **remembers their path over time**.

---

## Foundation — memories, not statistics

Without making predictions, track meaningful interactions:

| Memory | Source |
|--------|--------|
| **Completed readings** | `ReadingModel` in `or_reading_history` |
| **Favorite memories** | `RitualJournalMetadata.isFavorite` |
| **Recurring themes** | `PersonalInsightEngine` + `journal.tags` |
| **Personal notes** | `RitualJournalMetadata.personalNote` |
| **Session history** | Reading history timeline |

These are not statistics. They are **memories**.

---

## Design gates — never

| Forbidden | Why |
|-----------|-----|
| Streak counters | EPIC-011 — pressure, not peace |
| Spiritual level bars | Fake gamification |
| Predictive copy | Trust violation |
| Fabricated patterns | EPIC-010 — honesty |
| Leaderboards / scores | Not a companion |

---

## Visual language

History should not feel like a log.

It should feel like a **timeline** — a quiet archive of personal reflection.

- Month chapters in the timeline
- Day markers within chapters
- "Kişisel Arşiv" summary — notes, favorites, recurring cards
- Header: **Kişisel Yolculuk**

---

## AI foundation

Future AI features build upon this journey:

- Connect patterns **only from the user's own history**
- Never fabricate meaning
- Only summarize **observable patterns**
- Use uncertain, observational language ("olabilir", "beliriyor")

Anchor: `PersonalInsightEngine` + `PersonalJourneyService`

---

## Implementation

### Core files

```
lib/features/insights/
  models/personal_journey_snapshot.dart
  services/personal_journey_service.dart   # composes journey from readings
  services/personal_insight_engine.dart    # existing theme detection

lib/features/tarot/presentation/
  screens/reading_history_screen.dart      # journey timeline + archive
  screens/reading_history_detail_screen.dart  # favorite memory toggle
  utils/reading_history_timeline.dart      # month + day archive nodes
  widgets/reading_history/
    reading_history_summary.dart           # Kişisel Arşiv (memory stats)
    reading_history_header.dart            # Kişisel Yolculuk
    reading_history_filters.dart           # includes Hatıralar filter
```

### Persistence

No new storage keys. Journey is **computed** from existing `ReadingModel` history.

### Favorites

- `ReadingService.toggleFavorite()` — already persisted
- Detail screen bookmark toggle
- `HistorySpreadFilter.favorites` — "Hatıralar" chip

---

## Relationship to other EPICs

| EPIC | Relationship |
|------|--------------|
| **EPIC-010** | Legend = memory-rich; journey is the retention spine |
| **EPIC-011** | Daily ritual thoughts can join journey when linked to readings |
| **EPIC-007** | Remove gamified stats from history — done in EPIC-012 |
| **EPIC-004** | Journal metadata is the memory envelope |

---

## Success criteria

- [ ] `PersonalJourneyService` composes snapshot from readings
- [ ] History summary shows memory metrics, not streaks/spiritual level
- [ ] Timeline has month chapters + day markers
- [ ] Favorites filter and bookmark toggle work
- [ ] Insights use observational language only
- [ ] No navigation changes

---

## Success quote

> *ORACLY becomes a long-term companion — not because it nags, but because it quietly remembers.*
