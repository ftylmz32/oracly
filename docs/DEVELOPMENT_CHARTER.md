# ORACLY Development Charter

**Version:** 1.0  
**Status:** Canonical · Governs how ORACLY evolves from this point forward  
**Hierarchy:** [Master Directive](./MASTER_DIRECTIVE.md) → **Development Charter (this doc)** → [Manifesto (OR-000)](./vision.md) → [EPIC-003](./EPIC-003.md) → [EPIC-004](./EPIC-004.md) → [EPIC-005](./EPIC-005.md) → [EPIC-006](./EPIC-006.md) → [OOS](./OOS.md) → [PRINCIPLE-001](./PRINCIPLE-001.md) → [Gold Standard](./GOLD_STANDARD.md)

This document defines **how ORACLY will evolve** — what we build, what we refuse, and how we decide.

---

## Mission

ORACLY is not built to become the biggest spiritual application.

It is built to become **the most loved one**.

Size is not the goal. Depth of feeling is.

---

## We build

| We build | Not |
|----------|-----|
| **Experiences** | Screens |
| **Feelings** | Effects |
| **Trust** | Dependency |
| **Reflection** | Prediction |

Every line of code, every animation, every sentence serves one of the left column — or it does not ship.

---

## Every new feature must pass

Before any feature enters development, all five must be **yes**:

| # | Gate | Fails when… |
|---|------|-------------|
| 1 | Does it **improve the user's experience**? | It only adds surface area or parity |
| 2 | Does it **respect the user's intelligence**? | It manipulates, fakes, or condescends |
| 3 | Does it **strengthen ORACLY's identity**? | It feels like a bolt-on or second app |
| 4 | Would users still **appreciate it one year later**? | It's exciting only the first time |
| 5 | Does it **justify the engineering complexity**? | A simpler path preserves the same quality |

**If any answer is no — rethink the feature.**

Do not implement until it passes.

---

## Engineering principles

- **Readable code** — understood in five minutes, maintained for five years
- **Reusable systems** — one tile primitive, one chat stack, one ambient breath
- **Consistent architecture** — features under `lib/features/`, shared code only when truly shared
- **Maintainable components** — compose, don't duplicate; split before 150 lines when UI grows
- **Predictable behavior** — no dead taps, no infinite spinners, no settings that lie

Defer to [`docs/GOLD_STANDARD.md`](./GOLD_STANDARD.md) gates 5–6 for completion.

---

## Design principles

- **One design language** — OR Lattice, crystal frames, chamber gradients
- **One motion language** — `OraclySignatureMotion`, asymmetric press release
- **One emotional language** — calm, observational, Turkish soul at peaks
- **Every screen belongs to the same sanctuary** — if it feels like a different app, it is not ready

Defer to [`docs/EPIC-004.md`](./EPIC-004.md) for emotional recognizability.

---

## Product principles

- **Never build because competitors have it**
- **Build because ORACLY deserves it**

Ask: *Why does ORACLY deserve to exist because of this?*

Depth before breadth. The journal is the relationship. Tarot is the doorway. The sanctuary is the product.

Defer to [`docs/EPIC-003.md`](./EPIC-003.md) for identity.

---

## Quality principles

- **No rushed implementation** — proud to ship today, or keep refining
- **No temporary hacks** — no `onTap: () {}`, no fake stats, no mock commerce in production paths
- **No visual inconsistency** — grep existing components before creating new ones
- **No emotional inconsistency** — peak at reveal, calm in reading, honesty in profile

Defer to [`docs/PRINCIPLE-001.md`](./PRINCIPLE-001.md) for pixel-level craft.

---

## What we refuse to add

Automatic rejection — no debate required:

- Features exciting **only once**
- Gamified spirituality (streaks, XP, spiritual level bars as identity)
- Modality previews marketed as finished product
- Second visual, motion, or chat stacks
- Settings that persist but never apply
- Copy that predicts, guarantees, or creates fear
- Engineering complexity without user experience gain

---

## How evolution works

```
Idea
  → Master Directive: protect identity?
  → Development Charter: five feature gates?
  → EPIC-003: deepen self-relationship?
  → EPIC-004: same sacred place?
  → OOS: calmness wins?
  → PRINCIPLE-001: pixels earn place?
  → Build
  → Gold Standard: proud to ship?
  → Release
```

Remove features that fail the gates retroactively. The app should become **simpler over time**, not more complicated.

---

## The final question

> **Will we still be proud of this five years from now?**

If not — continue refining.

---

## Relationship to other documents

| Document | Answers |
|----------|---------|
| **Master Directive** | Why we protect ORACLY as permanent creators |
| **Development Charter** | **How ORACLY evolves — what we add and refuse** |
| **Manifesto** | Why ORACLY exists |
| **EPIC-003** | What ORACLY is (sanctuary) |
| **EPIC-004** | How ORACLY feels (same sacred place) |
| **OOS** | Daily operating rules |
| **PRINCIPLE-001** | Pixel and interaction craft |
| **Gold Standard** | Definition of done |

---

*Build experiences. Build trust. Build for return — not for feature count.*
