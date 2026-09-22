# ORACLY Master Operating Contract

**Status:** Permanent source of truth  
**Scope:** How ORACLY is built, shipped, and judged complete  
**Last updated:** 2026-09-22 (Night Shift / Project Memory)

---

## Product principles

- The user is **not** a tester.
- No known unfinished engineering may be intentionally shipped.
- Passing unit tests alone does **not** mean product completion.
- A feature is complete only when its **whole user ritual** works.
- No fake-success fallback in production.
- No invented memory.
- No invented user history.
- No fabricated visual evidence.
- No unsupported astrology calculation claims.
- **Current evidence** outranks historical context.
- Deleted user data must stop influencing future AI output.
- Account isolation is mandatory.
- Paid actions must obey **exactly-once** settlement.
- Premium grants require authoritative verification.
- User-facing claims must match real capability.
- Error states must be human, safe, and retryable.
- Restart / recovery is part of feature completion.
- Accessibility and responsive behavior are release requirements.
- Visual quality is a release requirement.
- Golden / reference visuals are acceptance evidence.
- Users must never be asked to discover defects for us.

---

## Release rule

ORACLY **MUST NOT** be submitted for public review/release until every canonical release blocker, product contract, and final acceptance gate is demonstrably complete.

This includes (non-exhaustive): remediation backlog P1s, production E2E proof for paid rituals, StoreKit / entitlement verification, and any locked product program marked NOT IMPLEMENTED.

---

## Locked brand / human intelligence principle

ORACLY must differentiate itself by making users feel:

- seen
- remembered
- understood
- respected
- cared about

**without:**

- fake therapy
- manipulative dependency
- robotic empathy
- generic AI encouragement
- invented familiarity
- empty mystical clichés

OR / Luna and interpretations should feel emotionally intelligent, specific, and human.  
Personalization must be **evidence-based**.

---

## Locked Tarot product decision

ORACLY keeps:

- classical 78-card Tarot system
- classical card identities
- authentic Tarot symbolism

Release-quality Tarot requires a **Narrative Tarot Engine**:

- structured semantic profile per card
- core meaning · light · shadow · tension/conflict · desire · fear
- relationship dynamic · decision dynamic · action direction
- real upright / reversed distinction
- spread-position semantics
- card-to-card relationship reasoning
- spread-level narrative arc
- question grounding
- evidence-based personalization
- recurring-card recognition using **real** history
- recurring-theme recognition with relevance checks
- no fabricated recurrence
- ORACLY Signature Spreads
- narrative-first result structure
- card details as secondary layer
- no forced Love / Career / Money sections when irrelevant
- anti-boilerplate · anti-flattery
- uncertainty / no deterministic fortune rules

**Language:** natural, specific, warm, honest, emotionally intelligent; sometimes challenging when evidence supports it.

**Never:** robotic, sycophantic, generic, template-like, fake mystical certainty.

---

## Locked Tarot visual system

Tarot release is **not** complete without a coherent ORACLY Visual System.

Required direction:

- card illustration remains primary artwork
- card must feel like a physical / premium object
- consistent frame / chrome
- signature ORACLY card back
- controlled depth / shadow · controlled glow · restrained particles
- editorial typography · ritual pacing
- premium card fan interaction
- cinematic but restrained flip / reveal
- selected-card focus · spread composition hierarchy
- Signature Spread–specific geometry
- narrative result visual hierarchy
- recurring-card history visual treatment
- Major / Minor presentation weight
- no casino / game-machine language
- no cheap mystical glow overload

**Golden / reference masters required** for at least:

Tarot Entry · Spread Selection · Card Fan · Reveal · 3-card composition · 5-card / The Mirror · Narrative Result · Card Detail · Recurring Card History · Loading · Error · large-text · 320-width · 390-width · reduced-motion

The product owner’s role is **product / visual approval**, not defect discovery.

---

## Engineering operating notes

- Prefer fail-closed honesty over silent local / canned success in production.
- Reuse existing AI policy (`allowsLocalFallback`) — do not invent parallel environment flags.
- Diff discipline: stage only intended files; never clean / reset / delete foreign worktrees as part of a task.
- Documentation of current reality (forensics) precedes Narrative Tarot / Visual System implementation.
