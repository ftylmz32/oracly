# ORACLY Gold Standard

**Status:** Canonical · Definition of done — no task is complete until all ten pass  
**Version:** 1.0  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → [Development Charter](./DEVELOPMENT_CHARTER.md) → [Manifesto (OR-000)](./vision.md) → [EPIC-003](./EPIC-003.md) → [EPIC-004](./EPIC-004.md) → [EPIC-005](./EPIC-005.md) → [EPIC-006](./EPIC-006.md) → [OOS](./OOS.md) → [PRINCIPLE-001](./PRINCIPLE-001.md) → **Gold Standard**

From this point onward, **every implementation must satisfy these requirements** before it can be considered complete.

---

## 1. Product

The feature must solve a **real user problem**.

Not a developer wish.  
Not a design trend.  
Not competitor parity.

**Gate:** Can you state the user problem in one sentence without mentioning technology?

---

## 2. Experience

The user should **immediately understand what to do**.

Nothing should require explanation.

**Gate:** Would a first-time user know the next step within three seconds — without a tooltip?

---

## 3. Emotion

Every interaction must increase at least one of:

- **Calmness**
- **Trust**
- **Curiosity**
- **Reflection**

Otherwise it should be **removed**.

**Gate:** Name which value increased. If none — do not ship.

---

## 4. Design

Reuse existing ORACLY systems.

Never introduce another visual language.

Spacing · Motion · Glass · Gold · Typography — everything belongs to **one family**.

**Canonical sources:** `OraclySignatureMotion` · `OraclyPressable` · `OraclyCrystalFrame` · `GlassCard` · `OraclyRhythm` · `OraclyTypography` · chamber gradients

**Gate:** Did you grep for an existing component before creating a new one?

---

## 5. Engineering

Readable · Maintainable · Reusable · Performant.

No unnecessary complexity.

**Gate:** Would a new developer understand this in five minutes? Would you maintain it for five years?

---

## 6. Performance

No unnecessary rebuilds.  
No unnecessary animations.  
No unnecessary layers.

Performance is part of premium quality.

**Gate:** One ambient loop per screen. `RepaintBoundary` on heavy paint. No `repeat()` per list item. 60 FPS minimum on mid-tier devices for the changed surface.

---

## 7. Accessibility

Readable · Touchable · Inclusive · Comfortable.

**Gate:** Contrast meets AA for body copy. Touch targets ≥ 44×44 logical pixels. Critical actions have semantics labels where applicable.

---

## 8. Longevity

Ask: **Will this still feel correct in five years?**

If not — rethink it.

Avoid trends. Prefer timeless craftsmanship.

**Gate:** Same question as OOS final rule and EPIC-004 ten-year rule.

---

## 9. Quality gate

Before marking a task complete:

> **Would I proudly ship this today?**

If not — keep refining.

**Gate:** `flutter analyze` passes · tests pass · no dead affordances · no placeholder copy in user paths.

---

## 10. ORACLY rule

Never build something merely because it looks impressive.

Build it because users will **remember how it made them feel**.

**Gate:** Does this improve ORACLY — or only make it different?

---

## Completion checklist

Copy before closing any task:

```
[ ] 1. PRODUCT     — Real user problem stated
[ ] 2. EXPERIENCE  — Next step obvious, no explanation needed
[ ] 3. EMOTION     — Calmness / trust / curiosity / reflection increased
[ ] 4. DESIGN      — Existing ORACLY systems reused; one visual family
[ ] 5. ENGINEERING — Readable, maintainable, no unnecessary complexity
[ ] 6. PERFORMANCE — No extra rebuilds, animators, or layers
[ ] 7. ACCESSIBILITY — Readable, touchable, inclusive
[ ] 8. LONGEVITY   — Still correct in five years
[ ] 9. QUALITY     — Proud to ship today; analyze + tests pass
[ ] 10. ORACLY     — Users will remember the feeling, not the feature
```

---

## Relationship to other docs

| Doc | Role |
|-----|------|
| **Manifesto** | Why ORACLY exists |
| **EPIC-003** | What ORACLY is (sanctuary) |
| **EPIC-004** | How ORACLY feels (same sacred place) |
| **OOS** | How the team operates day-to-day |
| **PRINCIPLE-001** | How pixels and interactions behave |
| **Gold Standard** | **When work is allowed to be called done** |

Strategy guides decisions. Gold Standard gates completion.

---

*Impressive is easy. Memorable is the standard.*
