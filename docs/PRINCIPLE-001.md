# PRINCIPLE-001 — Every Pixel Must Earn Its Place

**Status:** Permanent · Applies to every implementation without explicit instruction  
**Parent:** [Master Directive](./MASTER_DIRECTIVE.md) · [Development Charter](./DEVELOPMENT_CHARTER.md) · [OR-000 Manifesto](./vision.md) · [EPIC-003](./EPIC-003.md) · [EPIC-004](./EPIC-004.md) · [EPIC-005](./EPIC-005.md) · [EPIC-006](./EPIC-006.md) · [OOS](./OOS.md)  
**Version:** 1.0

---

## Core Belief

Every visible element must justify its existence.  
Every animation must have emotional purpose.  
Every interaction must improve the user's experience.

If it does not — **remove it**.

---

## Design Rules

Never decorate for decoration.  
Never animate for animation.  
Never glow because glow looks premium.

Every visual decision must reinforce at least one of:

- **Calmness**
- **Trust**
- **Curiosity**
- **Reflection**
- **Craftsmanship**

If a visual choice serves none of these, it does not ship.

---

## User Experience

The user must never feel: confused, rushed, overwhelmed, or manipulated.

They must feel: **safe, curious, present, and respected**.

---

## Consistency

Before creating a new screen or component:

1. Inspect existing ORACLY components
2. Reuse design language, motion, spacing, lighting, emotional rhythm
3. Never introduce a second visual language

**Canonical systems (reuse, do not fork):**

| System | Source |
|--------|--------|
| Motion / press | `OraclySignatureMotion`, `OraclyPressable` |
| Chamber / color | `OraclySignatureChamber`, `OraclySacredPalette` |
| Typography | `OraclySignatureTypography`, `OraclyTypography` |
| Glass / crystal | `OraclyCrystalFrame`, `GlassCard` |
| Spacing / rhythm | `OraclyRhythm`, `AppSpacing` |
| Emotional peaks | `tarot_emotional_rhythm.dart` |

---

## Engineering

- Prefer **reusable systems** over one-off effects
- Avoid **duplicate implementations** (one tile primitive, one chat stack, one background language)
- Prefer **maintainability** and **clarity** over cleverness
- Future developers should immediately understand the code

Before adding a widget, grep for an existing one. Extend or compose — do not parallel-stack.

---

## Quality Check

Before completing any task:

> **Does this improve ORACLY — or simply make it different?**

Only improvements survive.

Also run the manifesto gates ([vision.md](./vision.md)):

- Feeling test · Five-year test · Disappearance test · Honesty test

---

## Implementation Checklist

Every task must pass before done:

- [ ] Every new visible element has a stated purpose (comment or PR note)
- [ ] No decoration-only layers (particles, glow, ornaments) without emotional job
- [ ] No dead affordances (tappable visuals without working `onTap`)
- [ ] Reused existing tokens/components where possible
- [ ] No second press curve, background system, or tile pattern introduced
- [ ] User would feel calmer or more respected — not more stimulated

---

## Success

Every future feature should feel like it **always belonged** inside ORACLY.

Nothing should feel added.  
Everything should feel **discovered**.

---

*When in doubt, protect the pause.*
