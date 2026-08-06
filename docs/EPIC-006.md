# EPIC-006 — Invisible Excellence

**Status:** Canonical · Final quality pass — refine until excellence disappears  
**Version:** 1.0  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → [Development Charter](./DEVELOPMENT_CHARTER.md) → [Manifesto (OR-000)](./vision.md) → [EPIC-003 Identity](./EPIC-003.md) → [EPIC-004 Soul](./EPIC-004.md) → [EPIC-005 Living Universe](./EPIC-005.md) → **EPIC-006 Invisible Excellence** → [OOS](./OOS.md) → [PRINCIPLE-001](./PRINCIPLE-001.md) → [Gold Standard](./GOLD_STANDARD.md)

---

You are the **final quality team** before ORACLY reaches the public.

Your mission is not to add.

Your mission is to **refine what already exists** until excellence becomes invisible.

---

## Mission

Review the entire application from the perspective of **invisible quality**.

Users should never consciously notice these improvements.

They should simply feel that ORACLY is **exceptionally well crafted**.

---

## Checklist

Review every screen and every interaction. Look for:

| Category | What to inspect |
|----------|-----------------|
| **Spacing** | Inconsistent padding, edge alignment |
| **Motion** | Uneven animation timing, transition continuity |
| **Typography** | Rhythm, hierarchy, optical balance |
| **Touch** | Press confidence, gesture responsiveness |
| **Flow** | Loading smoothness, empty/error states |
| **Shell** | Safe area handling, keyboard appearance, scroll behavior |
| **Focus** | Visual balance, icon optical balance |

---

## Engineering

- Remove unnecessary complexity
- Reduce duplicated logic
- Improve readability and maintainability
- Improve performance where possible
- **Do not rewrite stable systems**

---

## Design

Everything should feel **inevitable**.

Nothing should feel **accidental**.

Nothing should look **unfinished**.

Every component should appear **intentionally crafted**.

---

## Product

| Signal | Action |
|--------|--------|
| Creates friction | Remove the friction |
| Creates confusion | Clarify it |
| Creates delight | Protect it |

---

## Quality gate

**Do not add features.**  
**Do not redesign.**  
**Only elevate the craftsmanship of what already exists.**

Pass [Development Charter](./DEVELOPMENT_CHARTER.md) gates before any polish work ships.

---

## Implementation notes (v1.0 pass)

### Motion unification
All pressables align to `OraclySignatureMotion`:
- `pressScale` 0.982 · `pressOpacity` 0.96
- `press` 220ms · `pressRelease` 280ms
- `curve` easeOutCubic · `releaseCurve` easeOutQuart

### Transitions
Tarot detail routes use `tarotRitualRoute` — same fade/slide/scale language as the ritual flow.

### States
Bare `Text` error/empty branches replaced with `OraclyErrorState` / `OraclyEmptyState` where users encounter failure.

### Trust
Dead header taps wired to navigation — visible affordances must respond.

---

## Success

When users finish their first session, they should not think:

> "This app has amazing animations."

They should think:

> **"This app simply feels… right."**

---

## Final question

Would a user notice we polished — or would they only notice that nothing feels wrong?

If they notice the polish, it was too much. Continue refining.
