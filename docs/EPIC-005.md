# EPIC-005 — The Living Universe

**Status:** Canonical · Environmental system — the observatory breathes with time  
**Version:** 1.0  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → [Development Charter](./DEVELOPMENT_CHARTER.md) → [Manifesto (OR-000)](./vision.md) → [EPIC-003 Identity](./EPIC-003.md) → [EPIC-004 Soul](./EPIC-004.md) → **EPIC-005 Living Universe** → [EPIC-006 Invisible Excellence](./EPIC-006.md) → [OOS](./OOS.md) → [PRINCIPLE-001](./PRINCIPLE-001.md) → [Gold Standard](./GOLD_STANDARD.md)

---

You are no longer building screens.

You are **creating a living universe**.

Every time the user opens ORACLY, the world should feel slightly different — while remaining familiar.

---

## Mission

Create a subtle environmental system that evolves over time.

The user should never consciously notice every change.

But after weeks of use, they should feel the application is **alive**.

---

## Environmental states

Without changing layouts, the environment evolves through:

| Channel | What shifts | How subtle |
|---------|-------------|------------|
| **Moon phase lighting** | Veil, crystal shimmer, warmth | ±2–4% opacity |
| **Seasonal palettes** | Particle warmth, atmospheric density | Whisper-level |
| **Particle density** | Opacity multiplier only | Never count changes |
| **Crystal reflections** | Breath and shimmer layers | Nearly invisible |
| **Atmospheric intensity** | Nebula, traveling light | ±6% max |
| **Sacred observatory ambience** | Composite veil from ritual + moon + season | One sanctuary |

Changes must be **extremely subtle**. Never distract. Never affect readability.

---

## Ritual time

| Window | Hours | Emotional atmosphere |
|--------|-------|----------------------|
| **Morning** | 05:00–11:59 | Hopeful warmth, brighter crystal |
| **Afternoon** | 12:00–16:59 | Neutral clarity, balanced chamber |
| **Evening** | 17:00–20:59 | Soft gold-purple transition |
| **Night** | 21:00–04:59 | Deeper calm, quieter particles |

No redesign. Only environmental refinement.

---

## Living details

Rare ambient events may occur — at most **one per day**, on roughly **14% of days**:

| Event | When | Duration |
|-------|------|----------|
| Faint shooting star | Evening, night | ~2.8s once |
| Distant glow | Night | ~9s breathe |
| Slowly shifting constellation | Any ritual window | Wall-clock drift |
| Quiet golden reflection | Morning, evening | ~4.8s once |

Their **rarity creates delight**. They must never demand attention.

---

## Performance

- Wall-clock computation — no perpetual universe loop
- At most **one** short `AnimationController` when a timed event plays
- Constellation drift reuses existing phase channels
- `RepaintBoundary` on event layer
- Respect battery life and low-end devices

---

## Implementation

```
lib/core/universe/
  oracly_ritual_time.dart      — Morning / Afternoon / Evening / Night
  oracly_moon_phase.dart       — Lunar lighting influence
  oracly_season.dart           — Seasonal palette bias
  oracly_living_event.dart     — Rare daily events
  oracly_universe_state.dart   — State + modulation math
  oracly_universe_painters.dart — Event painters
  oracly_universe_layer.dart   — Ambient layer + scope + hourly ticker
```

**Integrated at:** Home observatory (`HomeCosmicBackground`, `HomePage` via `OraclyUniverseTicker`).

**Future:** Chamber profiles for tarot ritual screens — same state, profile-specific modulation.

---

## Success

Users should never say:

> "The background changed."

Instead they should feel:

> "Somehow… this place never feels exactly the same."

**The observatory feels alive.**

---

## Gates (Development Charter)

Before extending the universe:

1. Does it improve experience? → Must feel alive, not busy
2. Respect intelligence? → Never gamified, never announced
3. Strengthen identity? → Same sanctuary, evolving breath
4. Appreciated one year later? → Subtlety compounds trust
5. Justify complexity? → Lightweight wall-clock math only

Any **no** → rethink.

---

## Final question

Will the observatory still feel sacred — not decorative — five years from now?

If not, continue refining.
