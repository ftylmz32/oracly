# EPIC-009 — Obsessive Craftsmanship

**Status:** Canonical · Master craftsman pass — nothing neglected  
**Version:** 1.0  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → … → [EPIC-008 Final Illusion](./EPIC-008.md) → **EPIC-009 Obsessive Craftsmanship** → [EPIC-010 Legendary Product](./EPIC-010.md) → [AI Agent Guide](./AI_AGENT_GUIDE.md)

---

You are no longer an engineer.

You are a **master craftsman** finishing a work that will carry your name forever.

Every detail matters. Every compromise lasts for years.

---

## Mission

Walk through the entire ORACLY application **slowly**.

Do not search for missing features.

Search for **missed opportunities**.

---

## The craftsman test

For every component ask:

> *If I spent another hour on only this component, could it become meaningfully better?*

| Answer | Action |
|--------|--------|
| **Yes** | Improve it |
| **No** | Protect it |

---

## The five senses

Even though this is software, imagine physical properties:

**Weight · Depth · Texture · Temperature · Silence**

Let those qualities influence every refinement.

---

## Avoid

Visual noise · Unnecessary brilliance · Artificial luxury · Copying trends · Design that seeks attention

---

## Pursue

Precision · Restraint · Balance · Harmony · Timelessness

---

## Review everything

Buttons · Cards · Typography · Spacing · Animation timing · Motion curves · Glass · Lighting · Shadows · Icons · Alignment · Scrolling · Touch feedback · Transitions · Loading · Errors · Success states

---

## Implementation patterns (v1.0)

| Craft | System |
|-------|--------|
| Loading presence | `ChamberWaitingOrb` — never Material spinners on CTAs |
| Feedback | `OraclySnackBar` / `OraclyDialog` — never raw Material |
| Press | Scale 0.982 + opacity 0.96 + haptic — one language |
| Glass | `OraclySignatureMaterials.blurChamber` + `crystalBody()` |
| Dead affordances | Remove or wire — never fake taps |
| Copy | Chamber voice — *"Evren dinleniyor..."* not *"Yükleniyor..."* |

---

## Final question

If ORACLY were displayed next to the finest digital products in the world,

would anything quietly reveal that it was made with **less care**?

If yes — refine **only that**.

---

## Success

The goal is not perfection.

The goal is that **nothing feels neglected**.

Every visible detail should communicate:

> **"Someone truly cared."**

---

## Quality gate

Defer to [EPIC-006](./EPIC-006.md) (craftsmanship), [EPIC-008](./EPIC-008.md) (illusion), [AI Agent Guide](./AI_AGENT_GUIDE.md) (daily decisions).

Protect what passes the craftsman test. Refine what fails it.
