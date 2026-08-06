# EPIC-011 — The Daily Ritual

**Status:** Canonical · Gentle daily return — ritual, not reward  
**Version:** 1.0  
**Perspective:** Design a reason to return that respects the user  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → … → [EPIC-010 Legendary Product](./EPIC-010.md) → **EPIC-011 Daily Ritual** → [AI Agent Guide](./AI_AGENT_GUIDE.md)

---

> *You are designing a daily ritual, not a daily reward.*

Do not gamify ORACLY. Do not create addiction loops.

Create a reason to return that respects the user.

---

## Mission

Introduce a gentle daily ritual.

| Constraint | Rule |
|------------|------|
| **Duration** | 30–90 seconds |
| **Pressure** | Never |
| **Offer** | One meaningful moment |

---

## The ritual

The user arrives.

The observatory quietly welcomes them.

Today's atmosphere is unique.

One thoughtful reflection is offered.

The user may:

- draw today's card
- read today's reflection
- write one personal thought

Then leave.

**The ritual feels complete.**

---

## Design gates — never

| Forbidden | Why |
|-----------|-----|
| Streak counters | Fear-driven return |
| FOMO copy | Manipulation |
| Countdowns | Artificial urgency |
| Spirit percentages | Fake stats (EPIC-010) |
| Achievement unlocks for daily use | Gamification |

---

## Emotional goal

The user returns because they **enjoy the ritual**.

Not because they fear losing progress.

---

## Implementation

### Core files

```
lib/features/daily_ritual/
  models/daily_ritual_day.dart
  services/daily_ritual_service.dart      # date-keyed local state
  services/daily_ritual_intent.dart       # cross-tab card draw
  services/daily_ritual_reflections.dart  # universe-aware copy
  widgets/daily_ritual_card.dart          # home replacement for static energy
  widgets/daily_ritual_thought_sheet.dart
  widgets/daily_ritual_tarot_bridge.dart  # tarot tab intent handler
```

### Home integration

`DailyRitualCard` replaces `DailyEnergyCard` on `HomePage` — same glass surface, honest copy.

Uses `OraclyUniverseScope` for atmosphere-aware welcome and reflection pools (EPIC-005).

### Tarot integration

`OraclyNavigationService.startDailyCardDraw()` → single-card spread → existing ritual pipeline.

`DailyRitualTarotBridge` consumes intent on the tarot tab inside `TarotScope`.

### Persistence

Date-keyed `SharedPreferences` keys — private, never scored:

- `daily_ritual_reflection_YYYY-MM-DD`
- `daily_ritual_card_YYYY-MM-DD`
- `daily_ritual_thought_YYYY-MM-DD`

No streaks. No leaderboard. No visible counter.

---

## Legend test (EPIC-010)

| Pillar | How the ritual serves it |
|--------|--------------------------|
| **Wonder** | Atmosphere shifts daily via living universe |
| **Comfort** | No pressure, optional steps |
| **Reflection** | Thoughtful copy + personal note |
| **Beauty** | Same observatory glass language |
| **Trust** | Honest, non-predictive copy |
| **Memorability** | "A quiet place I return to each day" |

---

## Relationship to other EPICs

| EPIC | Relationship |
|------|--------------|
| **EPIC-005** | Ritual time, moon, season, rare events shape reflection pools |
| **EPIC-008** | Chamber breath, no spinners — ritual waiting stays calm |
| **EPIC-009** | Signature press on ritual chips, themed thought sheet |
| **EPIC-010** | Replaces static daily energy mock; no gamification |

---

## Success criteria

- [ ] Home shows `DailyRitualCard` instead of static daily energy
- [ ] Three optional actions: draw card, read reflection, write thought
- [ ] No streaks, countdowns, or FOMO anywhere in ritual UI
- [ ] Reflection copy varies by universe state but stays deterministic per day
- [ ] Closing line appears after any engagement — ritual feels complete
- [ ] Single-card draw routes through existing tarot ritual pipeline

---

## Success quote

> *ORACLY becomes part of a healthy routine — not a habit driven by pressure, but by peace.*
