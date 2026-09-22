# NARRATIVE TAROT SPEC — Product Behavior Contract

**Program:** ORACLY Narrative Tarot V2
**Document kind:** PRODUCT BEHAVIOR (no runtime code)
**Branch:** `fix/final-product-remediation-20260922`
**Depends on:** `ORACLY_MASTER_OPERATING_CONTRACT.md`, `TAROT_PHASE0_FORENSIC_BASELINE.md`
**Status:** Phase 1 architecture/spec — **NOT IMPLEMENTED**

---

## 1. Product promise

### Core sentence

> **Kartlar artık ayrı ayrı konuşmuyor. Açılım konuşuyor.**

### Differentiation

ORACLY Tarot is not a catalogue reader that dumps Love / Career / Money blocks per card.

The user must feel:

> “The app did not read card definitions to me.
> It understood the spread I drew and answered what I asked.”

### What a reading interprets (as ONE coherent whole)

| Input | Role |
|---|---|
| Question / intention | Primary emphasis when real |
| Cards (canonical identity) | Authentic symbolism preserved |
| Orientation (upright / reversed) | Materially different transforms |
| Position | Changes what the card is doing in the story |
| Card relationships | Support, conflict, cause/effect, etc. |
| Spread purpose | Shapes narrative geometry and length |
| Relevant verified history | Optional support — never overrides current draw |

Independent card summaries are **secondary detail**, never the primary product.

---

## 2. Non-negotiable reading principles

1. **Question-first** when a real question exists; open readings stay observational.
2. **Spread-level** interpretation — one story, not N card essays.
3. Classical card meanings remain **authentic**; narrative adapts, does not invent new cards.
4. **Upright / reversed** must materially differ (not “same + negative”).
5. **Positions** materially change meaning.
6. **Neighbor / relationship** evidence matters; contradictions between cards may be meaningful.
7. History may **support** but never **override** the current spread.
8. Memory only when **genuinely relevant**; omit when unsure.
9. **No fake recurrence**, **no fake familiarity**.
10. **No certainty** about unknowable future events.
11. **No** medical / death / legal deterministic prediction; no financial guarantees.
12. **No** empty “universe says” filler; **no** generic positivity; **no** flattery-to-please.
13. **Compassionate challenge** is allowed when evidence supports it.
14. Uncertainty is **natural** language, not robotic disclaimers inside the story.
15. Every conclusion must be **traceable** to current cards / positions / question / verified evidence.

---

## 3. Reading narrative shape

### Primary structure (locale names may vary)

| Beat | Purpose |
|---|---|
| **Opening** | What this spread is really pointing at |
| **Core tension** | Central friction / contradiction |
| **Movement** | How cards interact; where the situation shifts |
| **Turning point** | What matters most now |
| **Meaning for the user** | Direct answer to question / intention (or open reflection) |
| **Action / reflection** | Realistic notice or step — not commands |
| **Closing** | Brief human ending (aligns with EPIC-015 calm close) |

**Not primary:** Love · Career · Money · Health · Lucky Energy as forced top-level sections.

Legacy section fields may be adapted for old UI during migration (see Migration Plan) but must not drive V2 product.

### Length by spread

| Spread | Cards | Narrative length | Beat density |
|---|---|---|---|
| Single | 1 | Short — opening + meaning + closing; tension optional | Minimal relationships |
| Three-card | 3 | Medium — full arc; movement across past→present→future | Pair links expected |
| Five-card (classical) | 5 | Full arc; stronger core tension + turning point | Multi-card relationships |
| Seven-card | 7 | Full arc + denser movement; avoid repeating card essays | Selective relations (not all pairs) |
| Celtic Cross | 10 | Longest; still one story — cluster by narrative roles, not 10 monologues | Role clusters, not combinatorial explosion |
| Signature: The Mirror | 5 | Full arc keyed to mirror positions | Self-honesty emphasis |
| Signature: Between Us | 5 | Full arc keyed to relational positions | Dyadic dynamics |

Absolute word budgets are Phase 2 corpus concerns; Phase 1 rule: **complexity scales with cards and spread purpose, not with filler**.

### All-card coverage without ten mini-essays

Quality uses **`allCardsAccountedFor`** (not “every card in every beat”).

| Rule | Meaning |
|---|---|
| Accounted for | Every drawn card appears in **traceable** result data (beats and/or `cardDetails`) |
| Primary narrative | May prioritize cards/relationships that drive the arc |
| Equal paragraphs | **Not** required — especially Celtic Cross |
| Forbidden | Ignoring a drawn card entirely; contradicting or silently replacing a drawn card |
| Quality | Detect truly ignored cards without forcing repetitive prose |

---

## 4. Card semantic profile

### Canonical identity stays

`OraclyTarotDeck` / `OraclyTarotCard` remain the **canonical 78-card identity** (ids, names, arcana, suit, keywords, existing meanings, assets, relatedIds).

Phase 0 proved useful existing fields:

- `symbolicMeaning`, `challengeMeaning`, `guidanceMeaning`, `futureDirectionMeaning`
- `loveMeaning`, `careerMeaning`, `moneyMeaning`, `personalMeaning`
- upright / reversed keywords
- `OraclyTarotRelations`

### Required Narrative V2 concepts (per card)

| Field | Intent |
|---|---|
| `coreMeaning` | Stable essence |
| `light` | Constructive / clarifying aspect |
| `shadow` | Cost / distortion / wound aspect |
| `tension` | Inherent inner conflict of the card |
| `desire` | What the energy reaches toward |
| `fear` | What the energy avoids |
| `relationshipDynamic` | How it behaves between people |
| `decisionDynamic` | How it behaves at choice points |
| `actionDirection` | Realistic move / stance |
| `uprightTransform` | How upright expresses |
| `reversedTransform` | How reversed transforms (see §6) |
| `symbols` / motifs | Optional sparse tags for relations |

### Recommended architecture (Decision A)

**Separate keyed V2 layer: `NarrativeCardProfile` keyed by canonical card id**
(e.g. `major_00`, `cups_01`) — **not** mutating `OraclyTarotCard` fields in place.

| Criterion | Why separate profile wins |
|---|---|
| Backward compatibility | Ritual / catalogue / bridge keep working; old readings unchanged |
| Localization | Profile copy uses same `L10nTriple` (or locale maps) without rewriting card builders |
| Risk | Incomplete profiles allowed **only** in dev / migration / shadow — never production V2 |
| Maintainability | Narrative semantics evolve without touching 78 catalogue files blindly |
| Reuse | Profiles **derive / cite** existing meanings; adapters map symbolic→core, challenge→shadow seed |
| Testability | Profile completeness tests independent of UI / AI |

V2 **EXTENDS / ADAPTS** current data via adapters — does **not** duplicate 78 cards from scratch.

### Profile completeness / production release gate

| Context | Incomplete `NarrativeCardProfile` allowed? |
|---|---|
| Development / Phase 3 construction | YES — may seed from catalogue meanings |
| Migration / shadow validation | YES — documented fallback for corpus only |
| **Production user path for Narrative Tarot V2** | **NO** |

**Hard rule:** Narrative Tarot V2 **MUST NOT** become the production user path until **all 78** canonical cards have **complete** required profile coverage for **every release-supported locale** (tr / en / ru per app contract).

- Existing catalogue meanings are authored **source material** for building profiles.
- “Missing V2 profile → silent catalogue fallback” is **not** a production success condition.
- Deterministic completeness gate (Phase 2/3 harness) must fail the release switch if any required field is empty for any card/locale.

---

## 5. Card relationship model

### Relationship kinds (evidence vocabulary)

support · reinforcement · contrast · conflict · cause/effect · blockage · resolution · escalation · softening · theme repetition

### Scalability rule

**Do not** author all 78×77 combinations.

### Deterministic preprocessing (local)

Derive **candidates** from:

| Source | Use |
|---|---|
| `relatedIds` + relation notes | Strong prior links |
| Suit / element / Major–Minor | Soft thematic affinity or clash |
| Orientation pair patterns | e.g. upright support vs reversed blockage hypotheses |
| Position roles | cause vs outcome, self vs other, obstacle vs aid |
| Semantic traits from profiles | tension/desire/fear tag overlap |
| Adjacent interpretation order | Neighbor beats |

Emit `TarotNarrativeRelationshipEvidence[]` with:

- card ids + positions
- relationship kind
- confidence / strength band
- provenance (`relatedIds` | `suitAffinity` | `positionRoles` | `traitOverlap`)

### AI responsibilities

- Receive relationship **evidence**, not invent card physics from nothing.
- May **select and narrate** among candidates; may note meaningful contradiction.
- Must **not** invent related cards that were not drawn.
- Must **not** claim a relationship without evidence or drawn adjacency/role basis.

---

## 6. Upright / reversed contract

Reversed is **not**:

- “same meaning but negative”
- “prepend blockage”

### Allowed reverse transforms (profiles pick applicable ones)

| Transform | Sense |
|---|---|
| internalization | Energy turns inward |
| delay | Timing held back |
| excess | Too much of upright gift |
| deficiency | Too little / underfed |
| avoidance | Dodging the upright invitation |
| distortion | Meaning warped |
| blocked expression | Cannot show outwardly |
| misdirection | Energy aimed wrong |
| release | Letting go / emptying |
| private/internal form | Quiet, unseen enactment |

Each card’s `reversedTransform` documents which transforms apply. Engines must produce **materially different** upright vs reversed text when orientation differs.

---

## 7. Spread position semantics

Phase 0: labels reach AI; semantics are thin.

### First-class `SpreadPositionSemantic`

| Field | Purpose |
|---|---|
| `positionKey` | Stable id (`past`, `mirror_feeling`, …) |
| `role` | narrative role enum / string |
| `guidingQuestion` | what this slot asks (localized) |
| `temporalOrientation` | past / present / future / none |
| `narrativeFunction` | setup / conflict / aid / outcome / … |
| `relationToOtherSlots` | optional role graph edges |
| `weight` | relative importance (0–1 or band) |
| `displayLabel` | UI label (localized) |

Positions **influence interpretation**, not merely decorate.

---

## 8. Classical spreads (preserve)

| Spread | Purpose |
|---|---|
| **1 card** | Single sign / focus for the day or question |
| **3 card** | Movement across past → present → future (symbolic, not prophecy) |
| **5 card** | Situation, hidden influence, challenge, strength, direction |
| **7 card** | Deeper problem framing: question, energy, obstacle, hidden, help, avoid, direction |
| **Celtic Cross** | Full classical role map; narrate by clusters, not ten essays |

**Saved sessions** using existing `TarotSpreadType` must reopen without breakage.

---

## 9. ORACLY Signature Spreads (V1 set)

Do **not** implement in Phase 1. Spec only.

### Canonical signature spread ids (immutable once persisted)

| Stable persistence / domain id | Display name (locale may refine) |
|---|---|
| `signature.the_mirror` | THE MIRROR |
| `signature.between_us` | BETWEEN US |

**Rules:**

- These dotted ids are the **only** persisted/domain identifiers.
- Underscore forms such as `signature_the_mirror` are **deprecated / wrong** for persistence — never store them.
- **Stable spread ids are immutable once persisted.** Renames affect display/l10n only.
- Display / localized titles remain separate from ids.

### `signature.the_mirror` — THE MIRROR — 5 cards

| # | Semantic purpose |
|---|---|
| 1 | What am I actually feeling? |
| 2 | What am I telling myself? |
| 3 | What am I not seeing? |
| 4 | What is holding me here? |
| 5 | What can I do now? |

- **Narrative geometry hook:** vertical mirror / center axis (Visual System Phase 7).
- **Story expectation:** honesty about self-split; turning point on “not seeing”; action on slot 5.

### `signature.between_us` — BETWEEN US — 5 cards

| # | Semantic purpose |
|---|---|
| 1 | You |
| 2 | Them |
| 3 | The real dynamic between you |
| 4 | What remains unsaid |
| 5 | Where this connection is moving / what matters next |

- **Narrative geometry hook:** two poles + bridge (Visual System Phase 7).
- **Story expectation:** dyadic tension; no fabricated accusations; uncertainty preserved.

Localized display names may refine; **semantic purpose is the contract**.
Integration: new spread ids extend catalog **without** remapping old `TarotSpreadType` ordinals (Migration Plan §G).

---

## 10. Question grounding

| Input mode | Behavior |
|---|---|
| Explicit question | Opening + meaningForUser answer the ask; cards stay authentic |
| Topic-only (`love` / `career` / …) | Emphasize relevant dynamics; do not invent a fake question |
| Generic / open | Observational spread story; no forced topic sections |
| Relationship | Prefer Between Us semantics when on that spread; else relational dynamics from cards |
| Decision | Stress decisionDynamic / actionDirection; no “guaranteed right choice” |
| Career | Work/agency emphasis only when cards + ask support it |
| Emotion / self | Mirror-like inner tension; no therapy mimicry |

**Same cards + different questions ⇒ different emphasis**, never distorted card meaning to flatter the asker.

---

## 11. Memory / personalization

### Evidence hierarchy (strict)

1. **CURRENT SPREAD / QUESTION**
2. **DIRECT CURRENT USER CONTEXT** (intention topic, revisit instruction if active)
3. **RELEVANT RECENT VERIFIED HISTORY**
4. **LONGER-TERM MEMORY** (only if relevant)

History **never** overpowers the current draw.

### Omit memory when

- no verified history
- relevance score below threshold (Phase 2/4 defines metrics)
- account / privacy clear removed sources (R1)
- memory would invent familiarity

**No memory > irrelevant memory.**

---

## 12. Recurring cards

First-class capability. Claims only from **real stored readings**.

### Required evidence per occurrence

canonical card id · orientation · date · spread id · position key · question/intention summary if stored · source reading id

### Thresholds (contract defaults — Phase 4 may tune with tests)

| Claim type | Minimum |
|---|---|
| Soft “appeared again” | ≥ 2 occurrences in lookback window |
| Counted claim (“N times”) | Exact count from store; never round up |
| Theme recurrence | ≥ 2 overlapping **contexts**, not mere same card |

Lookback default: last **20** Tarot readings or **90 days**, whichever bound is hit first (bounded).

### Separate concepts

| Concept | Meaning |
|---|---|
| `TarotRecurringCardEvidence` | **Authoritative** same-card recurrence — contexts may differ |
| `TarotRecurringThemeEvidence` | **Authoritative** overlapping themes with relevance check |

### Recurrence authority (Phase 1.1)

Dedicated recurrence evidence is the **ONLY** authoritative source for explicit recurrence claims/counts in V2.

Legacy compatibility fields on memory (`recentCardNames`, `recurringThemeLabels`) may remain as **context hints** during migration but **MUST NOT** authorize statements such as:

- “This card has appeared 4 times”
- “This theme keeps returning”

unless dedicated deterministic recurrence evidence proves it.

Avoid duplicate/conflicting truth sources.

If contexts **differ**: acknowledge recurrence without inventing one shared problem.
If contexts **overlap**: may name an evidence-backed recurring theme.

**No fabricated recurrence.**

---

## 13. Human voice contract

### Good

specific · grounded · fluid · human · warm · observant · occasionally challenging · not overlong · not repetitive

### Bad

- “Evren sana…” / empty mystical authority
- “Bu kart sana diyor ki…” repeated per card
- generic motivational paragraphs
- AI disclaimers inside normal reading body
- therapy imitation / fake intimacy
- guaranteed predictions
- “everything will be okay” reflex
- constant praise / sycophancy

Reads as **one careful reading of the whole spread**, not nine stitched sections.

---

## 14. Safety / uncertainty

**Preserve** `SensitiveTopicGate` emergency path (R2 safety exception).

| Domain | Allowed | Forbidden |
|---|---|---|
| Self-harm | Crisis routing / safety copy | Fortune-telling the crisis |
| Death | Reflective symbolic only | Predicting death / disasters |
| Medical | Suggest care / non-diagnosis | Diagnosis, treatment certainty |
| Pregnancy | Reflective caution | Certainty claims |
| Legal | Reflective | Legal advice / outcome certainty |
| Financial | Reflective | Guarantees / “will profit” |
| Infidelity / crime | No accusations as fact | Declaring guilt / proof |
| Future certainty | Soft possibility language | Deterministic timelines |

Tarot supports reflection; it does **not** prove unknowable real-world facts.

---

## 15. Success experience (product Definition of Done)

1. Enter Tarot
2. Choose spread (classical or signature)
3. State intention / question (or skip honestly)
4. Select / shuffle / draw
5. Reveal (ritual pacing)
6. Wait for interpretation (intentional loading; fail-closed on failure)
7. Receive **narrative** primary result
8. Explore **card detail** as secondary layer
9. See **recurrence only if real**
10. Save / history / journal
11. Reopen later (versioned schema)
12. Share where supported

Complete only when this **whole ritual** works — not when unit tests alone pass.

---

## Architectural decisions (summary)

| ID | Decision |
|---|---|
| A | Separate `NarrativeCardProfile` keyed by canonical id |
| B | Reuse local `ReadingStory` / relations as **reference + deterministic seeds**; retire as production narrator after V2 AI narrative ships |
| C | Deterministic evidence builder → AI synthesizes narrative only |
| D | Recurrence calculated **locally** from stored readings before AI |
| E | Dual schema + legacy adapter during migration |
| F | Domain `TarotNarrativeResult` independent of widgets; UI maps beats |
| G | Signature spreads as new semantic definitions; preserve legacy enum/storage ids |
| H | Profile + position copy via L10n; AI writes in request language; no mixed-language bodies |

Detail: `NARRATIVE_TAROT_DATA_CONTRACT.md`, `NARRATIVE_TAROT_MIGRATION_PLAN.md`.
