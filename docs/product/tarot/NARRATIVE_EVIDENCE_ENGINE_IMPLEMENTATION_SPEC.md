# Narrative Evidence Engine — Implementation Specification

**Active revision:** Phase **3D.1B.1** scoring calibration (extends 3D.0.1 catalogs + 3D.1A/B signals)
**Phase 3D.0 start SHA:** e90a5109bbb75ce2c1247be686c9a149aa554846
**Phase 3D.0.1 start SHA:** 18cfeea804cc415a8d064e2a3f9d89c611c8cb4d
**Phase 3D.1B.1 calibration:** `docs/product/tarot/NARRATIVE_RELATIONSHIP_SCORING_CALIBRATION.md`
**Status:** **READY FOR 3D.1C** (OPEN 3D.1C SCORING DECISIONS = 0)
**Production scoring / builder:** **NOT IMPLEMENTED**

Authority: NARRATIVE_TAROT_SPEC.md · NARRATIVE_TAROT_DATA_CONTRACT.md · TAROT_KEYWORD_ONTOLOGY_FINAL_AUDIT.md · NARRATIVE_RELATIONSHIP_SCORING_CALIBRATION.md

### Phase 3D.0.1 hardening

Resolved before coding:

1. Complete classical spread + position + edge catalogs (no examples left)
2. TarotNarrativeProfileSlice replaces illegal NarrativeCardProfile as request-side slice type

### Phase 3D.1B.1 scoring calibration (ACTIVE for 3D.1C)

Raw `Σ w(id)` overlap **REJECTED** (saturates `[0,3.5]`). Chosen overlap:

`S_overlap = Σ (weight(id) / 6.0)` over FR-F04 `Chan∩`.

Full locks: family count · tag-only · question · orientation · kind trigger sets · FR keywordIds identity — see calibration doc + §§10–15 / §21 / §29 below.

Historical 3D.0 scoring/admission/safeguard decisions remain LOCKED unless superseded by 3D.1B.1.

---

## 0 — Pipeline lock

```
ReadingSession FACTS
  → NarrativeEvidenceBuilder   (THIS SPEC — deterministic)
  → TarotNarrativeRequest
  → later NarrativeAiSynthesizer     (Phase 6 — NOT NOW)
  → later NarrativeQualityValidator  (Phase 6 — NOT NOW)
  → later TarotNarrativeResult
```

Builder does **not** write Tarot prose. It builds a closed, traceable evidence universe.

---

## 1 — Current implementation inventory

| Concept | Classification | Exact path / type |
|---|---|---|
| `NarrativeCardProfile` | EXISTS-REUSE | `lib/features/tarot/narrative/domain/narrative_card_profile.dart` |
| `NarrativeOrientationProfile` | EXISTS-REUSE | `…/narrative_orientation_profile.dart` |
| `NarrativeKeywordIds` | EXISTS-REUSE | `…/narrative_keyword_ids.dart` (rev 1, 128 ids) |
| `NarrativeSymbolTags` | EXISTS-REUSE | `…/narrative_symbol_tags.dart` |
| `ReversedTransformKind` | EXISTS-REUSE | `…/reversed_transform_kind.dart` |
| `NarrativeTarotProfileCatalog` | EXISTS-REUSE | `…/data/narrative_tarot_profile_catalog.dart` |
| `OraclyTarotDeck` / `OraclyTarotCard` | EXISTS-REUSE | `lib/features/tarot/deck/` |
| `OraclyTarotRelations` | EXISTS-ADAPT | `…/oracly_tarot_relations.dart` — `relatedIds` + note only (no kind/strength) |
| `OraclyTarotBridge` | EXISTS-REUSE | ritual int ↔ canonical id |
| `TarotContentCatalogue` / `DeckService` | EXISTS-REUSE | ritual deck content |
| `TarotSpreadType` + positions | EXISTS-ADAPT | `domain/models/tarot_spread.dart`, `tarot_spread_positions.dart` |
| `ReadingAsk` / `ReadingAskKind` | EXISTS-ADAPT | `reading/reading_ask.dart` — map → `QuestionKind` |
| `ReadingQuestion` | EXISTS-REUSE | sanitize / `real` / max 280 |
| `TarotIntention` | EXISTS-REUSE | text + optional topic |
| `ReadingContext` | EXISTS-ADAPT | interim input shape; map into builder input |
| `JourneyPersonalizationHints` | DEFERRED-LATER-PHASE | **must not** become recurrence facts in 3D.1 |
| `TarotInterpretationService` / Engine / Executors | EXISTS-REUSE (untouched) | user path stays on current stack |
| `SensitiveTopicGate` | EXISTS-REUSE | pre-AI short-circuit — do not weaken |
| `ReadingRelations` / Story / Beat… | EXISTS-REUSE (legacy local narrative) | **not** Evidence Engine; do not merge |
| `NarrativeEvidenceBuilder` | MISSING-CREATE | Phase 3D.1 |
| `TarotNarrativeRequest` + evidence types | MISSING-CREATE | from data contract |
| `RelationshipKind` | MISSING-CREATE | from data contract |
| `QuestionGrounding` / `QuestionKind` | MISSING-CREATE | map from `ReadingAskKind` + topic |
| `SpreadSemanticDefinition` / position edges | MISSING-CREATE | catalog over existing position keys |
| `RequestBounds` | IMPLEMENTED (3D.1A) | 5 fields; defaults 20/5/12/800/4 |
| Memory / recurring evidence | DEFERRED-LATER-PHASE | Phase 4 — empty shells only |
| Signature spreads | DEFERRED-LATER-PHASE | Phase 5 |
| AI synthesizer / quality validator | DEFERRED-LATER-PHASE | Phase 6 |
| Visual system | DEFERRED-LATER-PHASE | Phase 7 |

**Counts:** REUSE **18** · ADAPT **5** · CREATE **12** · DEFER **6** (approx; see module plan).

---

## 2 — Phase 3D.1 scope boundary

### IN SCOPE

- Current draw facts (canonical card ids, orientation, positions, spread id, question)
- Profile attach via `NarrativeTarotProfileCatalog`
- Structured signals: `keywordIds`, `symbolTags`, `ReversedTransformKind`
- Question grounding
- Classical spread semantics + position relation edges
- Deterministic relationship candidate scoring / ranking
- Closed request-scoped `evidenceId`s
- Empty memory / empty recurrence placeholders
- Pure function: no network, no AI, no storage

### OUT OF SCOPE

- Memory / recurring cards / recurring themes implementation
- Signature Spreads
- AI narrative synthesis / result prose / quality validator
- Persistence migration / UI / visual / billing / user-path switch

---

## 3 — Phase 4 placeholders (mandatory empty)

Phase 3D.1 `TarotNarrativeRequest` **must** include:

```dart
memory: TarotNarrativeMemoryEvidence(
  entries: const [],
  priorReadingCount: 0,
  recentCardNames: const [],      // MUST remain empty — never copy JourneyPersonalizationHints
  recurringThemeLabels: const [], // MUST remain empty
  included: false,
  omitReason: 'empty',            // or 'none' only when Phase 4 fills
),
recurringCards: const [],
recurringThemes: const [],
```

**Forbidden:** fabricating familiarity from hints, history, or journal.

Only Phase 4 dedicated providers may authorize “appeared again” / “N times” / “keeps returning”.

---

## 4 — Fact / inference / narrative boundary

| Layer | Producer | AI may |
|---|---|---|
| **FACTS** | Session | never rewrite |
| **INFERENCES** | Builder | select / phrase later; not invent |
| **NARRATIVE** | Phase 6 | prose only |

**Facts:** card ids, ritual ids, orientation, position keys/indexes, spread id, question raw/kind, canonical metadata.

**Inferences:** relationship kind, strength, provenance, optional note key, profile field emphasis, current-spread theme echo.

---

## 5 — No deterministic prose parsing

Builder **MUST NOT** NLP/parse:

`coreMeaning`, `light`, `shadow`, `tension`, `desire`, `fear`, `relationshipDynamic`, `decisionDynamic`, `actionDirection`, orientation `expression`, or any localized prose

for scoring.

Scoring uses only: `keywordIds`, `symbolTags`, transforms, `OraclyTarotRelations.relatedIds`, spread position edges, orientation, question kind, stable metadata (suit/rank as attenuation only).

Prose is attached as content for later synthesis, not scored.

---

## 6 — Closed request universe

### Evidence id format (LOCKED)

- Pattern: `rel_` + zero-padded 2-digit index: `rel_01` … `rel_12`
- Assigned **after** final ranked selection, in final output order
- Deterministic for identical builder inputs (excluding external session/reading uuid fields which are passthrough)
- Opaque, request-scoped, non-private (no card ids / memory in the id string)

### Closed-universe rules

- AI may reference only supplied `evidenceId`s
- Unknown id ⇒ hard fail at quality stage (Phase 6)
- Builder must never emit duplicate `evidenceId`s

---

## 7 — RelationshipKind contract

Keep contract enum values. **Semantic lock for `themeRepetition`:** means **current-spread theme echo only** — NOT historical recurrence.

**Recommended rename before AI phase (docs/code in 3D.1):** keep wire value `themeRepetition` for contract compatibility **or** introduce alias `themeEcho` with deprecated synonym. **Decision for 3D.1A:** implement enum as in contract (`themeRepetition`) with dartdoc: *“Current-spread theme echo only. Never historical.”* Rename PR optional later — **not blocking**.

| Kind | Definition | Min evidence | Does NOT qualify | Position | Orientation | Safe implication | Forbidden |
|---|---|---|---|---|---|---|---|
| `support` | Cards cooperatively aid the same workable stance | ≥2 independent families **or** canonical relatedIds + ≥1 semantic | Shared HF keyword alone; Page set identity alone | Affinity edges help | Same polarity preferred | “these lean together” | destiny / guaranteed help |
| `reinforcement` | Cards amplify the **same** semantic atom | ≥2 families including specific (non-HF-only) overlap | Broad HF-only overlap | Neutral | Same polarity | “same theme intensifies” | “you always…” |
| `contrast` | Structured opposite / productive tension | Explicit contrast-pair hit **or** position opposition + semantic | Synonym restatement | Opposition edges boost | Upright↔reversed may contribute | “these pull differently” | moral judgment |
| `conflict` | Active friction / opposition beyond mild contrast | Contrast + challenge/obstacle position **or** conflict-leaning keywords | Mere difference | challenge/obstacle edges | Often reversed involved | “friction is present” | enemy/accusation |
| `causeEffect` | Temporal or positional “leads into” | Position temporal edge required + ≥1 semantic | Keyword overlap alone | past→present→future etc. | Any | “A informs B’s condition” | prediction certainty |
| `blockage` | One card stalls / obstructs another’s movement | obstacle/challenge/hidden edge **or** delay/resistance/block keywords + other signal | Generic delay HF alone | obstacle edges | Reversed often | “something impedes” | permanent curse |
| `resolution` | Softening/integrating toward workable close | strength/direction/outcome affinity + supportive semantics | Wishful reading | direction/outcome/helps | Prefer constructive | “a way through appears” | guaranteed fix |
| `escalation` | Intensity / haste / excess climbing | excess/haste/anger-like overlap + position pressure | Single HF haste | challenge+near_future etc. | Reversed excess | “intensity rises” | panic prophecy |
| `softening` | Cooling / restraint / compassion easing heat | restraint/compassion/pause overlap + supportive edge | Random calm keyword | strength/helps | Often upright | “heat can cool” | toxic positivity |
| `themeRepetition` | ≥2 **current** cards share a material theme | See §29 | Historical recurrence language | Any | Any | “this theme appears in more than one place in **this** spread” | “again / keeps returning” |

---

## 8 — Signal channels (independent families)

| ID | Family | Source | Alone can admit? | Dedupe | Contradiction |
|---|---|---|---|---|---|
| A | Keyword semantic overlap | orientation `keywordIds` (channel-normalized) | **NO** | with C | vs B / polarity |
| B | Keyword semantic contrast | explicit contrast map (§14) | **NO** (needs second family or position) | — | overrides soft A |
| C | SymbolTag overlap | `symbolTags` after FR-F04 merge | **NO** | merged into A channel | — |
| D | Transform interaction | `ReversedTransformKind` lists | **NO** | dual-name with keyword | weak only |
| E | Canonical relations | `OraclyTarotRelations.relatedIds` membership | **YES** as *strong seed* **only if** + ≥1 other family (A/B/C/D/F/G/H) | — | outranks soft A |
| F | Spread-position edge | semantic catalog edges | **YES** for `causeEffect`/`blockage` kinds when edge type matches **and** ≥1 semantic family | — | shapes kind |
| G | Orientation pair pattern | upright/reversed pairing | **NO** | — | supports contrast |
| H | Question-kind relevance | `QuestionKind` boost/penalty | **NO** | — | reweights, never invents |
| I | Suit/rank context | metadata | **NO** — attenuate/veto/tie-break only | — | FR-F01/F02 |

**Independent family count:** A and C count as **one** family after dedupe (SemanticChannel). D is independent of SemanticChannel. E, F, G, H are independent.

---

## 9 — Keyword / symbolTag dedupe (FR-F04) — LOCKED

Per card orientation:

```
semanticChannelIds = unique( keywordIds ∪ { t ∈ symbolTags | t ∈ NarrativeKeywordIds.all } )
```

Tags **not** in the keyword ontology remain tag-only extras (separate weak TagOnly set) and **do not** double a keyword.

**Overlap scoring** between two cards uses `semanticChannelIds` intersection only once per id.

Same id on keyword + tag on the **same** card ⇒ **one** contribution.

---

## 10 — High-frequency keyword discrimination — LOCKED formula

Let:

- `N = 156` (orientations in ontology revision 1)
- `df(id)` = number of orientations containing `id` (frozen table derived from production catalog at ontologyRevision 1; ship as const map in `narrative_keyword_discrimination.dart`)
- Raw weight (discrimination primitive — **unchanged**):

\[
w(id) = \ln\frac{N+1}{df(id)+1} + 1
\]

Clamp: `w_raw = clamp(w, 1.0, 6.0)`.

### Overlap contribution — ACTIVE 3D.1B.1 (supersedes raw Σ)

**Historical 3D.0 proposal** `S_overlap = Σ w_raw` is **REJECTED**: exhaustive C(156,2) simulation showed single-id min ≈3.35 and 93% of overlapping pairs already ≥3.5 against `S_total` max 3.5.

**Chosen formula:**

\[
S_{overlap} = \sum_{id \in Chan(A)\cap Chan(B)} \frac{w_{raw}(id)}{6.0}
\]

Revision-1 normalized per-id range (used ids): **≈ 0.558 → 0.894**.

**Rule:** a single shared id with `df ≥ 8` (scatter, haste, withdrawal, escape, isolation, control, delay, display, fear, …) **cannot** alone admit a relationship — even if `S_overlap` is nonzero.

Ship frozen `df` map keyed by ontology revision; rebuild only when ontologyRevision bumps.

Authority detail: `NARRATIVE_RELATIONSHIP_SCORING_CALIBRATION.md`.

---

## 11 — Multi-signal admission — LOCKED

A pair **admits** iff **any** of:

1. **Standard:** `independentFamilyCount ≥ 2` **AND** `S_total ≥ 1.25`
2. **Canonical seed:** E true (mutual or one-way `relatedIds` contains the other) **AND** `independentFamilyCount ≥ 2` (E counts as one) **AND** `S_total ≥ 1.0`
3. **Position-strong:** F edge present with kind affinity **AND** ≥1 of {A/B/D} **AND** `S_total ≥ 1.0`

Where `S_total` = weighted sum of channel contributions (overlap, contrast, transform, canonical bonus, position bonus, question bonus) after contradiction penalties (§24). Tag-only and orientation contribute **0** numeric (3D.1B.1).

**Never admit** on: one shared keyword only; FR-F01/F02 keyword-identical sets alone; HF-only single id.

### Independent family count (3D.1B.1 LOCKED)

| Family | Counts when |
|---|---|
| SEMANTIC (A) | `S_overlap > 0` on FR-F04 `semanticIds` |
| CONTRAST (B) | hard/contextual contrast hit |
| TRANSFORM (D) | non-empty `effectiveSharedTransforms` |
| CANONICAL (E) | undirected relatedIds |
| POSITION (F) | authoritative edge |
| ORIENTATION (G) | **never alone** (provenance only with B or D) |
| QUESTION (H) | `S_question > 0` |

Tag-only motif overlap: **0 family · 0 score** (provenance `symbolTag` only).

---

## 12 — FR-F01 Page safeguard — LOCKED

If both cards are Pages (`rank == page` / id suffix `_11`) **and** orientation **`keywordIds` sets are equal** **and** suits differ:

- Cap `S_overlap` contribution at **0.35**
- Force `independentFamilyCount` from SemanticChannel alone to count as **at most 1**
- Require **another** family (E, F, D, B, or H with structured support) before admission
- Max emitable strength for such pairs: **0.45** (weak)

Applies to known case: `wands_11` upright ↔ `pentacles_11` upright.

**3D.1B.1 clarification:** identity uses **`keywordIds`**, not full FR-F04 `semanticIds`. Production Pages share keywords but differ in symbolTags; full-Chan equality would incorrectly bypass the guard.

---

## 13 — FR-F02 Swords Page/Knight safeguard — LOCKED

If same suit **and** ranks are {page, knight} **and** orientation **`keywordIds` sets are equal**:

- Same caps as FR-F01 (overlap ≤0.35; channel family ≤1; need another family; strength ≤0.45)

Applies to: `swords_11` reversed ↔ `swords_12` reversed.

**Same keywordIds-identity clarification as §12.**

---

## 14 — Contrast / polarity map — LOCKED (explicit table)

Hardcoded reviewed pairs only — **no** string antonym inference.

| Left | Right | Class |
|---|---|---|
| balance | imbalance | HARD CONTRAST |
| stability | instability | HARD CONTRAST |
| belonging | isolation | HARD CONTRAST |
| abundance | scarcity | HARD CONTRAST |
| clarity | confusion | HARD CONTRAST |
| truth | denial | HARD CONTRAST |
| union | isolation | HARD CONTRAST |
| momentum | haste | CONTEXTUAL CONTRAST (productive vs premature motion) |
| nurture | rescue | CONTEXTUAL CONTRAST (care vs over-saving) |
| pause | delay | CONTEXTUAL CONTRAST |
| boundary | coldness | CONTEXTUAL CONTRAST |
| opening | closing | HARD CONTRAST |
| joy | despair | HARD CONTRAST |
| hope | despair | HARD CONTRAST |
| listening | notListening | HARD CONTRAST |

**DO NOT TREAT AS CONTRAST:** momentum↔direction, haste↔scatter (related difficulties, not opposites), control↔rigidity (adjacent), delay↔pause without context pair hit.

HARD CONTRAST hit ⇒ family B fires; soft overlap of unrelated ids does not cancel B.

---

## 15 — Transform signal contract — LOCKED

Transforms contribute family D:

- Shared transform set size ≥1 ⇒ weak bonus `+0.15` each unique shared kind, cap `+0.30`
- Alone: **never** admits
- Dual-name (`delay` keyword + `delay` transform): count transform bonus **or** keyword channel once for that name — **not both** (prefer keyword in SemanticChannel; suppress transform self-name double-count)
- Different transforms do not auto-contrast without B or position

---

## 16 — Canonical relations (`OraclyTarotRelations`) — LOCKED consume rules

**What exists:** undirected `List<String> relatedIds` + localized `note` on `OraclyTarotCard`. No kind, no strength, not directional.

**Consume:**

- If `cardA.relationshipWithOtherCards.relatedIds` contains `cardB.id` **or** reverse ⇒ family E true
- Canonical bonus `+0.55` once
- **Do not** parse `note` prose for scoring
- **Do not** fabricate missing relations
- E outranks incidental keyword overlap in kind resolution toward `support`/`reinforcement` when semantics agree; if B contrast also fires, prefer `contrast`/`conflict` over support

---

## 17 — Position semantics — classical spreads in 3D.1 (ACTIVE — 3D.0.1)

**Authority:** runtime keys from `tarot_spread_positions.dart` + `TarotSpreadType`.
**No examples. No TBD. No implementer choice.**

### 17.1 Closed enums

```dart
enum TemporalOrientation { past, present, future, atemporal }

/// Structural role of a slot. In 3D.1 classical catalog,
/// narrativeFunction MUST equal role (identity lock — no dual unexplained strings).
enum PositionRole {
  signal,
  context,
  root,
  state,
  challenge,
  hiddenInfluence,
  support,
  direction,
  self,
  environment,
  hopeFear,
  outcome,
  question,
  avoid,
}

typedef NarrativeFunction = PositionRole; // 3D.1 identity alias

enum NarrativeGeometryHook {
  singlePoint,   // 1 card
  linearRow,     // 3 / 5 / 7
  celticCross,   // 10
}

/// Carried metadata for later AI length policy (Phase 6). Not scored in 3D.1.
enum NarrativeLengthBand { short, medium, full, long }
```

### 17.2 Spread catalog (5/5)

| spreadId | legacyTypeName | cardCount | purposeKey | interpretationOrder | geometryHook | lengthBand |
|---|---|---:|---|---|---|---|
| `classical.single` | `single` | 1 | `purpose.classical.single` | `[0]` | `singlePoint` | `short` |
| `classical.threeCard` | `threeCard` | 3 | `purpose.classical.threeCard` | `[0,1,2]` | `linearRow` | `medium` |
| `classical.fiveCard` | `fiveCard` | 5 | `purpose.classical.fiveCard` | `[0,1,2,3,4]` | `linearRow` | `full` |
| `classical.sevenCard` | `sevenCard` | 7 | `purpose.classical.sevenCard` | `[0,1,2,3,4,5,6]` | `linearRow` | `full` |
| `classical.celticCross` | `celticCross` | 10 | `purpose.classical.celticCross` | `[0,1,2,3,4,5,6,7,8,9]` | `celticCross` | `long` |

**purposeKey rule:** machine-only semantic token. No production l10n added in 3D.1. Phase 6/7 may localize later. Display titles continue to use existing `tarot.spread.<legacyTypeName>`.

**geometryHook:** carried domain metadata only — **0 widgets, 0 coordinates, 0 visual deps**. Phase 7 owns visuals.

**Signature spreads:** not in this catalog (Phase 5).

### 17.3 Position catalog (26 rows)

**Common locks for every row:**

- `weight` = **1.0** (no authoritative numeric weights exist on `TarotPosition`)
- `displayLabelKey` = `tarot.pos.<positionKey>` (verified runtime: `TarotPosition.label` / `TarotL10n.position`)
- `guidingQuestionKey` = `gq.classical.<legacyTypeName>.<positionKey>` — **machine-only token**; no user-facing l10n in 3D.1 (Phase 6 may add copy)
- `role` = `narrativeFunction` (identical enum value)
- `relationToOtherSlots` = projection of §17.4 edges incident to this position (must match edge table)

#### single (`classical.single`)

| positionKey | index | role (= narrativeFunction) | temporal |
|---|---:|---|---|
| `sign` | 0 | `signal` | `atemporal` |

#### threeCard

| positionKey | index | role | temporal |
|---|---:|---|---|
| `past` | 0 | `root` | `past` |
| `present` | 1 | `state` | `present` |
| `future` | 2 | `direction` | `future` |

#### fiveCard

| positionKey | index | role | temporal |
|---|---:|---|---|
| `situation` | 0 | `context` | `atemporal` |
| `hidden_influence` | 1 | `hiddenInfluence` | `atemporal` |
| `challenge` | 2 | `challenge` | `atemporal` |
| `strength` | 3 | `support` | `atemporal` |
| `direction` | 4 | `direction` | `future` |

#### sevenCard

| positionKey | index | role | temporal |
|---|---:|---|---|
| `question` | 0 | `question` | `atemporal` |
| `current_energy` | 1 | `state` | `present` |
| `obstacle` | 2 | `challenge` | `atemporal` |
| `hidden_factor` | 3 | `hiddenInfluence` | `atemporal` |
| `what_helps` | 4 | `support` | `atemporal` |
| `what_to_avoid` | 5 | `avoid` | `atemporal` |
| `direction` | 6 | `direction` | `future` |

#### celticCross

| positionKey | index | role | temporal |
|---|---:|---|---|
| `present` | 0 | `state` | `present` |
| `challenge` | 1 | `challenge` | `atemporal` |
| `distant_past` | 2 | `root` | `past` |
| `recent_past` | 3 | `root` | `past` |
| `crown` | 4 | `direction` | `atemporal` |
| `near_future` | 5 | `direction` | `future` |
| `self` | 6 | `self` | `atemporal` |
| `environment` | 7 | `environment` | `atemporal` |
| `hopes` | 8 | `hopeFear` | `atemporal` |
| `outcome` | 9 | `outcome` | `future` |

**Temporal note:** `future` / `near_future` are positional narrative ordering only — **not** prediction certainty.

### 17.4 Complete position edge table (authoritative)

Edge kinds: `temporal` | `opposition` | `supportive` | `pressure` | `mirror`

| # | spread (legacyTypeName) | fromPositionKey | toPositionKey | directed | edgeKind |
|---:|---|---|---|---|---|
| 1 | `threeCard` | `past` | `present` | YES | `temporal` |
| 2 | `threeCard` | `present` | `future` | YES | `temporal` |
| 3 | `threeCard` | `past` | `future` | YES | `temporal` |
| 4 | `fiveCard` | `situation` | `direction` | YES | `temporal` |
| 5 | `fiveCard` | `situation` | `hidden_influence` | NO | `pressure` |
| 6 | `fiveCard` | `situation` | `challenge` | NO | `opposition` |
| 7 | `fiveCard` | `challenge` | `strength` | NO | `supportive` |
| 8 | `fiveCard` | `strength` | `direction` | YES | `supportive` |
| 9 | `fiveCard` | `hidden_influence` | `challenge` | NO | `pressure` |
| 10 | `sevenCard` | `question` | `current_energy` | NO | `mirror` |
| 11 | `sevenCard` | `current_energy` | `obstacle` | NO | `opposition` |
| 12 | `sevenCard` | `obstacle` | `what_helps` | NO | `supportive` |
| 13 | `sevenCard` | `what_to_avoid` | `direction` | NO | `pressure` |
| 14 | `sevenCard` | `hidden_factor` | `current_energy` | NO | `pressure` |
| 15 | `sevenCard` | `question` | `direction` | YES | `temporal` |
| 16 | `sevenCard` | `what_helps` | `direction` | YES | `supportive` |
| 17 | `sevenCard` | `obstacle` | `what_to_avoid` | NO | `pressure` |
| 18 | `celticCross` | `distant_past` | `recent_past` | YES | `temporal` |
| 19 | `celticCross` | `recent_past` | `present` | YES | `temporal` |
| 20 | `celticCross` | `distant_past` | `present` | YES | `temporal` |
| 21 | `celticCross` | `present` | `near_future` | YES | `temporal` |
| 22 | `celticCross` | `present` | `challenge` | NO | `opposition` |
| 23 | `celticCross` | `self` | `environment` | NO | `mirror` |
| 24 | `celticCross` | `present` | `self` | NO | `mirror` |
| 25 | `celticCross` | `challenge` | `outcome` | NO | `pressure` |
| 26 | `celticCross` | `hopes` | `outcome` | NO | `pressure` |
| 27 | `celticCross` | `crown` | `outcome` | YES | `temporal` |
| 28 | `celticCross` | `challenge` | `self` | NO | `pressure` |
| 29 | `celticCross` | `near_future` | `outcome` | YES | `temporal` |

`single`: **0** edges.

**Edge count:** **29**
**Directed rows:** **13** (projected onto source position only — no fake reverse directed edge)
**Undirected rows:** **16** (projected onto both endpoints with `directed:false`)
**Projected relation entries:** **45** (= 13 + 16×2)
**Edge kind type:** `PositionEdgeKind` enum (not free-form strings)
**Ambiguous/example edges remaining:** **NO**

**Sanity:** temporal edges encode narrative ordering, not guaranteed causation. `causeEffect` still requires §11 semantic family in addition to a temporal edge.

### 17.5 Role model decision (LOCKED)

- Engine uses **`PositionRole`** as the sole structural token.
- Data-contract field `narrativeFunction` is retained for compatibility and **MUST equal `role`** for every classical 3D.1 position.
- No second unexplained vocabulary.

---

## 18 — Position weighting & edge bonuses — LOCKED (3D.0.1)

### Position.weight

**ALL classical positions: `weight = 1.0`.**

Rationale: no production numeric weights exist; relationship importance comes from typed edges + edge bonuses (avoids double-counting “challenge importance”).

### Edge family F bonuses (unchanged from 3D.0)

| edgeKind | bonus |
|---|---:|
| `opposition` | +0.40 |
| `temporal` | +0.35 |
| `supportive` | +0.30 |
| `pressure` | +0.35 |
| `mirror` | +0.25 |

Kind resolution / contradiction rules in §7 / §21 / §24 unchanged.

Interpretation-order distance remains tie-break only (§22).

---

## 19 — Question grounding — LOCKED

Map existing `ReadingAsk.kind(raw)`:

| `ReadingAskKind` | `QuestionKind` |
|---|---|
| `decision` | `decision` |
| `relationship` | `relationship` |
| `guidance` | `guidance` |
| `other` | `open` |

Optional `topic` from `TarotIntention.topic` / Epic031 (`love|career|daily|general|money|custom`) on `QuestionGrounding.topic` — never invents card facts.

`hasRealQuestion = ReadingQuestion.real(raw) != null`.

Question may reweight candidates (±0.15 max), never create relations alone.

---

## 20 — TarotNarrativeProfileSlice contract — LOCKED (3D.0.1)

### 20.1 Type decision

`TarotNarrativeCardEvidence.profileSlice` is **`TarotNarrativeProfileSlice`**, **not** `NarrativeCardProfile`.

- `NarrativeCardProfile` = complete authored source (catalog)
- Builder **derives** a bounded request-side slice; **never mutates** the source profile

### 20.2 Exact shape

```dart
class TarotNarrativeProfileSlice {
  // REQUIRED base
  final L10nTriple coreMeaning;
  final L10nTriple orientationExpression; // exact drawn orientation only
  final List<String> keywordIds;          // exact drawn orientation only
  final List<String> symbolTags;          // card-level, unchanged
  final List<ReversedTransformKind> transforms; // upright → []; reversed → actual

  // OPTIONAL / question-emphasis (null when not selected)
  final L10nTriple? light;
  final L10nTriple? shadow;
  final L10nTriple? tension;
  final L10nTriple? desire;
  final L10nTriple? fear;
  final L10nTriple? relationshipDynamic;
  final L10nTriple? decisionDynamic;
  final L10nTriple? actionDirection;
}
```

No `canonicalCardId` inside the slice (owned by card evidence).
Domain models keep `L10nTriple`. Phase 6 owns locale flattening / AI serialization.

### 20.3 Question → optional field matrix (EXACT)

**Required base (all kinds):** `coreMeaning`, `orientationExpression`, `keywordIds`, `symbolTags`, `transforms`

| QuestionKind | Optional fields present (others null) |
|---|---|
| `open` | `light`, `shadow`, `tension` |
| `guidance` | `light`, `shadow`, `tension`, `actionDirection` |
| `relationship` | `relationshipDynamic`, `desire`, `fear`, `tension` |
| `decision` | `decisionDynamic`, `actionDirection`, `tension`, `fear` |

**Why `fear` on decision:** avoidance/risk/hesitation context for later synthesis — **content only**; never scored via prose NLP.

### 20.4 Orientation / keywords / transforms / tags

| Field | Rule |
|---|---|
| `orientationExpression` | Exactly one: upright.expression XOR reversed.expression matching draw |
| `keywordIds` | Exact drawn orientation set only |
| `transforms` | upright → empty; reversed → that orientation’s transforms |
| `symbolTags` | Card-level list unchanged |
| Scoring | Never parses any L10nTriple prose |

### 20.5 Integrity tests (future 3D.1)

Source profile not mutated · correct orientation · exact optional matrix · non-selected null · keywords/transforms from drawn orientation · tags unchanged · no prose in scoring.

---
## 21 — Relationship candidate generation — LOCKED

- Max cards: **10** (celticCross)
- Internal pairs: all unordered pairs `C(n,2) ≤ 45`
- Score each pair → kind resolve → filter by admission → rank → take top **`maxRelationships = 12`**
- Assign `rel_01…` in final order

### Score components (deterministic) — ACTIVE 3D.1B.1

```
S_total =
  S_overlap                   // Σ (w_raw/6.0) on Chan∩  [NOT raw Σ w]
+ S_contrast                  // HARD +0.70 / CONTEXTUAL +0.45
+ S_transform                 // +0.15 × |effectiveShared| cap +0.30
+ S_canonical                 // +0.55 if E (undirected relatedIds)
+ S_position                  // §18 edge bonuses
+ S_question                  // 0 or +0.15 (§11 / calibration §8)
− S_penalty_fr                // FR-F01/F02 caps already applied in overlap
− S_contradiction             // if HARD CONTRAST and soft support lobbied: −0.60 to support pathway
```

`S_tag_only = 0` · `S_orientation = 0` (3D.1B.1).

Clamp `S_total` to `[0, 3.5]` then map to strength:

`strength = clamp(S_total / 3.5, 0.0, 1.0)`

### Kind resolution precedence

1. If HARD CONTRAST or (CONTEXTUAL CONTRAST + opposition edge) ⇒ `contrast` or `conflict`
   - `conflict` iff contrast condition AND (opposition edge incident to role ∈ {challenge, avoid} OR HARD contrast + pressure edge); else `contrast`
2. Else if temporal edge + SEMANTIC ⇒ `causeEffect` (narrative flow; not literal causation)
3. Else if blockage semantics (calibration §10) ⇒ `blockage`
4. Else if softening semantics ⇒ `softening`
5. Else if escalation semantics ⇒ `escalation`
6. Else if resolution semantics + supportive edge ⇒ `resolution`
7. Else if theme-echo rule (§29) ⇒ `themeRepetition`
8. Else if E or strong overlap ⇒ `support` / `reinforcement`
   - `reinforcement` iff ≥2 shared ids with `df < 8` AND mean **raw** `w_raw ≥ 4.0`; else `support`
9. Else drop

Exact keyword/transform trigger sets: `NARRATIVE_RELATIONSHIP_SCORING_CALIBRATION.md` §10.

---

## 22 — Deterministic ordering — LOCKED

Sort admitted candidates by:

1. `strength` descending
2. `abs(positionIndexA - positionIndexB)` ascending
3. `min(positionIndexA, positionIndexB)` ascending
4. `leftCanonicalId` lexicographic ascending
5. `rightCanonicalId` lexicographic ascending

For each pair, normalize left/right so `left` is the lower `positionIndex`; if equal index (impossible), lower `canonicalCardId`.

No hash-map iteration order dependence: materialize pairs from cards sorted by `positionIndex` then `canonicalCardId`.

---

## 23 — Relationship strength — LOCKED

- Range: `0.0 … 1.0`
- Bands: weak `<0.40` · moderate `0.40–0.69` · strong `≥0.70`
- Admission uses §11 (`S_total`), not band alone
- **Never** present as probability / “80% likely”

---

## 24 — Contradiction overrides overlap — LOCKED precedence

1. HARD CONTRAST (B)
2. Explicit position opposition (F)
3. CONTEXTUAL CONTRAST
4. Canonical E agreeing with contrast reading
5. Specific keyword overlap (high w')
6. Generic / HF overlap
7. Transform-only similarity

If (1) or (2) fire, do **not** emit `support`/`reinforcement` for that pair.

---

## 25 — Suit / rank role — LOCKED

- **Never** “both Cups ⇒ support” / “both Queens ⇒ same theme”
- Suit mismatch attenuates FR-F01 as in §12
- Rank adjacency FR-F02 as in §13
- Suit/rank may appear in tie-break only after §22 keys (optional 6th key: suit name) — **Decision:** do **not** add suit to tie-break (keep §22 as final)

---

## 26 — Card evidence slice

See §20. Minimum fields per card evidence follow data contract `TarotNarrativeCardEvidence`.

---

## 27 — Provenance tokens — LOCKED

Machine-readable, pipe-joined sorted unique tokens, e.g. `canonicalRelation|keywordOverlap|positionEdge`.

Approved set:

`keywordOverlap` · `keywordContrast` · `symbolTag` · `transform` · `canonicalRelation` · `positionEdge` · `orientationPair` · `questionRelevance` · `themeEcho` · `pageSuitGuard` · `courtRankGuard`

No user text inside provenance.

---

## 28 — Note contract — LOCKED

`noteKeyOrText`:

- Prefer `null`
- Else bounded key only: `note.rel.<kind>.<shortCode>` from a closed catalog (≤40 keys)
- **Forbidden:** free-form narrative sentences from builder

---

## 29 — Current-spread theme echo (`themeRepetition`) — LOCKED

Emit at most **one** theme-echo relationship (or a dedicated optional list later — **Decision:** encode as `RelationshipKind.themeRepetition` between the two strongest supporting cards, strength = echo score):

**Admit theme echo iff:**

- ≥2 cards share SemanticChannel id set intersection mass `S_overlap ≥ 2.0` (**normalized** §10 formula) using **non-HF-only** contribution: at least one shared id with `df < 8`
- OR ≥3 cards each pairwise share the same specific id with `df ≤ 6`

Under 3D.1B.1 normalization, `2.0` ≈ two–three strong semantic atoms (single-id max ≈0.89 cannot qualify).

HF-only scatter/haste clusters **do not** create themeRepetition.

Copy must never imply historical recurrence.

---

## 30 — Memory / recurrence firewall — LOCKED

Builder pure over:

```
NarrativeEvidenceInput {
  sessionId, readingId, languageCode,
  questionRaw, intentionTopic?,
  spreadType,
  List<{canonicalCardId, ritualCardId, isReversed, positionKey, positionIndex}>,
}
```

`ritualCardId` is **required** (non-null) on domain card evidence and builder input — matches ritual draw identity / OraclyTarotBridge.

**Tests must prove:** no HistoryService, no JourneyPersonalizationHints read, no SharedPreferences, no recurring computation.

---

## 31 — Safety firewall — LOCKED

Forbidden evidence kinds / provenances / note keys implying:

partnerIsJealous · cheating · criminality · mentalIllness · pregnancy · death · guaranteedOutcome · destinedPartner · mindReadingClaim

Special ids `envy|projection|fear|attachment|control|rescue|bondage` may appear only as semantic channel members — never escalate to accusation kinds.

---

## 32 — SensitiveTopicGate boundary

Keep current placement in `TarotInterpretationService` **before** AI. Phase 3D.1 does not call the gate (deterministic, no prose). Phase 6 synthesizer wiring must still run gate before AI. Builder must not bypass or duplicate crisis prose.

---

## 33 — Performance / bounds

| Bound | Value |
|---|---|
| Network | 0 |
| Pair candidates | ≤45 |
| Emitted relationships | ≤12 |
| Cards | ≤10 |
| Complexity | O(n²) deterministic |

No fragile wall-clock gates; assert structural bounds in tests.

---

## 34 — Error contract — LOCKED typed failures

`NarrativeEvidenceError` sealed codes:

| Code | When |
|---|---|
| `unknownCanonicalCardId` | id not in deck/catalog |
| `profileMissing` | `NarrativeTarotProfileCatalog.lookup` null |
| `duplicatePositionKey` | two cards same positionKey |
| `cardCountMismatch` | cards.length ≠ spread.expectedCount |
| `unknownPositionKey` | key ∉ spread catalog |
| `invalidOrientation` | missing upright/reversed profile slice |
| `spreadMismatch` | unknown `TarotSpreadType` |
| `invalidOntologyId` | keyword/tag not in ontology (should be impossible) |
| `duplicateEvidenceId` | builder invariant broken |

**No silent partial success.** Builder errors do **not** trigger AI provider retries.

---

## 35 — Worked admission examples (≥20)

| # | Pair / case | Expected |
|---|---|---|
| 1 | wands_11↑ ↔ pentacles_11↑ keyword-identical Pages | **NO** strong relation; admit only if other family; strength≤0.45 |
| 2 | swords_11↓ ↔ swords_12↓ identical rev sets | same as 1 |
| 3 | wands_08↑ (momentum…) ↔ wands_08↓ (haste…) | contrast / contextual momentum–haste if co-present across cards |
| 4 | major_11↑ balance ↔ card with imbalance | HARD CONTRAST → contrast/conflict |
| 5 | same card keyword+tag `belonging` | dedupe once |
| 6 | only shared `scatter` | **reject** |
| 7 | only shared `haste` | **reject** |
| 8 | relatedIds hit + shared specific keyword | admit support/reinforcement |
| 9 | threeCard past↔present temporal + semantic | causeEffect candidate |
| 10 | fiveCard challenge↔strength | opposition/supportive → contrast or softening per semantics |
| 11 | sevenCard obstacle↔what_helps | blockage/resolution pathway |
| 12 | celtic present↔challenge | conflict/contrast lean |
| 13 | two cups belonging + position supportive | support |
| 14 | clarity↔confusion pair | contrast |
| 15 | delay keyword + delay transform same card vs other | no double-count |
| 16 | theme echo with rare id across 3 cards | themeRepetition |
| 17 | HF cluster across 3 cards only | **no** themeRepetition |
| 18 | relationship question boosts relationshipDynamic slice | slice only; no fake relation |
| 19 | single-card spread | 0 relationships |
| 20 | unknown card id | hard fail |
| 21 | stability↔instability | HARD CONTRAST |
| 22 | nurture↔rescue contextual | contrast only with second signal |
| 23 | canonical E + HARD CONTRAST | prefer contrast over support |
| 24 | empty question open kind | valid; no invention |

(Implement as fixture scenarios; expand to ≥40 in corpus §38.)

---

## 36 — Test architecture (paths)

```
test/features/tarot/narrative_evidence/
  narrative_evidence_builder_test.dart
  narrative_question_grounding_test.dart
  narrative_spread_semantics_test.dart
  narrative_keyword_discrimination_test.dart
  narrative_keyword_contrasts_test.dart
  narrative_relationship_scorer_test.dart
  narrative_evidence_bounds_test.dart
  narrative_evidence_errors_test.dart
  narrative_evidence_corpus_test.dart
test/features/tarot/narrative_evidence/red_team/
  narrative_evidence_fr_f01_f02_f04_test.dart
  narrative_evidence_safety_firewall_test.dart
  narrative_evidence_determinism_test.dart
  narrative_evidence_no_memory_test.dart
```

---

## 37 — Red-team regressions (required)

FR-F01 · FR-F02 · FR-F04 · one-keyword reject · HF-alone reject · contradiction>overlap · byte-stable structure (excluding session/reading ids) · unknown card/position fail · no recurrence · no memory query · no unsafe accusation evidence

---

## 38 — Fixed evidence corpus

**Path:** `test/fixtures/tarot_narrative_evidence_v1.json`

**Minimum scenarios:** **40** covering single/3/5/7/10, question kinds, all RelationshipKinds Phase 3D.1 can emit, no-relation, FR-F01/F02/F04, safety, polarity, position contradictions.

Do **not** modify Phase 2 `narrative_tarot_v2_corpus.json`.

---

## 39 — Implementation module plan (CREATE later — do not create in 3D.0)

Under `lib/features/tarot/narrative/evidence/`:

| File | Responsibility |
|---|---|
| `narrative_evidence_builder.dart` | Public API `build(input) → TarotNarrativeRequest` |
| `narrative_evidence_models.dart` | Request/evidence/bounds/errors (or split if >150 lines) |
| `narrative_relationship_candidate.dart` | Internal candidate struct |
| `narrative_relationship_scorer.dart` | Score + kind resolve + admission |
| `narrative_keyword_discrimination.dart` | Frozen df map + w(id) |
| `narrative_keyword_contrasts.dart` | Contrast table |
| `narrative_spread_semantics.dart` | Spreads, edges, interpretation order |
| `narrative_question_grounding.dart` | ReadingAsk → QuestionGrounding |
| `narrative_semantic_channel.dart` | FR-F04 merge |

Reuse deck/profile/catalog imports; no UI.

Honor **≤150 lines/file** rule via splits.

---

## 40 — Implementation subphases

| Subphase | Scope |
|---|---|
| **3D.1A** | Models + QuestionGrounding + SpreadSemantics + empty memory/recurrence + errors |
| **3D.1B** | Semantic channel + discrimination + contrasts + transforms |
| **3D.1C** | Pair scoring, kind resolution, admission, ranking, evidence ids |
| **3D.1D** | Full `NarrativeEvidenceBuilder` + 40-scenario corpus |
| **3D.1E** | Independent red-team / readiness audit (read-only) |

One writer at a time. **No user-path wiring.**

---

## 41 — Definition of Done (Evidence Engine)

All §40 items green; 3C.5F twelve safeguards enforced; FR-F01/F02/F04 tests green; safety green; no memory/recurrence fabrication; bounds enforced; corpus green; profile/Phase2/R2 regressions green; full Flutter green; independent audit PASS; **user path unchanged**.

---

## 42 — No live AI / economy effect

3D.1 implementation: **0** AI calls · **0** gem charges · **0** billing · **0** persistence · **0** journal/history writes · **0** shadow providers.

---

## 43 — Spec decision table (OPEN = 0)

| Decision | Chosen answer | Rationale | Impl | Test |
|---|---|---|---|---|
| Prose parsing | Forbidden | Audit + architecture | no NLP | static review |
| maxRelationships | 12 | Data contract | RequestBounds | bounds test |
| Pair ceiling | C(n,2)≤45 | 10-card max | scorer | complexity |
| Evidence id | `rel_##` | Contract example | assign post-rank | determinism |
| themeRepetition meaning | Current-spread echo only | 3C.5F / Phase4 firewall | dartdoc + tests | no “again” |
| Enum rename | Keep `themeRepetition` + dartdoc | Avoid contract churn | comment | — |
| Admission | §11 exact | Multi-signal lock | scorer | red-team |
| IDF formula | §10 | Stable, testable | discrimination | unit |
| Tag dedupe | §9 | FR-F04 | channel | red-team |
| Contrast | Explicit table §14 | No string antonyms | contrasts | polarity |
| Canonical relations | relatedIds membership only | Actual API | E flag | unit |
| Spreads in 3D.1 | All 5 with full §17 catalog | 3D.0.1 complete | semantics | lookup |
| Position weights | All 1.0 | No production weights; avoid double-count with edges | positions | unit |
| Role vs narrativeFunction | Identity lock (same enum value) | Remove dual unexplained strings | models | unit |
| purposeKey | Machine token purpose.classical.* | No new l10n in 3D.1 | catalog | — |
| guidingQuestionKey | Machine token gq.classical.* | No new l10n in 3D.1 | catalog | — |
| displayLabelKey | 	arot.pos.<key> | Runtime verified | catalog | unit |
| geometryHook | Enum carried metadata only | Phase 7 visual | catalog | — |
| lengthBand | short/medium/full/long mapped | Phase 6 prose policy | catalog | — |
| Edge table | 29 authoritative rows | No examples | edges | unit |
| profileSlice type | TarotNarrativeProfileSlice | Cannot use full NarrativeCardProfile | models | slice tests |
| Signature spreads | Defer Phase 5 | Scope | none | — |
| Question kinds | Map ReadingAskKind | Exists | grounding | unit |
| Strength range | 0–1 | Contract | map S_total | — |
| Tie-break | §22 | Determinism | sort | golden |
| Memory in 3D.1 | Empty omitReason empty | Phase4 | builder | no_memory |
| Hints as recurrence | Forbidden | Audit | — | red-team |
| Note policy | null or key catalog | No second narrator | — | — |
| Suit in tie-break | No | Simplicity | — | — |
| Celtic included | Yes in catalog | Engine-ready | semantics | — |
| User path | Unchanged | Charter | no wiring | — |
| SensitiveTopicGate | Unchanged pre-AI | Safety | Phase6 note | — |
| Dual delay count | Prefer keyword; suppress transform self-name | 3C.5F | scorer | unit |
| FR-F01/F02 caps | §12–13 | Audit minors | scorer | red-team |
| Theme HF | No HF-only themeRepetition | Audit | §29 | red-team |
| Builder errors | Typed; no AI retry | Fail-closed | errors | unit |
| Corpus size | ≥40 | Coverage | fixture | corpus |
| File location | `narrative/evidence/` | Feature boundary | create 3D.1 | — |
| Subphases | 3D.1A–E | Reviewability | prompts | — |
| Score→strength | S_total/3.5 | Bounded | scorer | — |
| Independent families | §8 after dedupe | Multi-signal | — | — |
| Position edge model | Typed edges catalog | Needed; positions exist, edges don't | CREATE | — |
| Journey hints | Not read | Firewall | — | no_memory |

**OPEN IMPLEMENTATION DECISIONS: 0**
**SPEC READY FOR 3D.1A: YES**

---

## 44 — Acceptance contract for Phase 3D.1A (do not execute now)

### Scope

Create **models (incl. TarotNarrativeProfileSlice) + question grounding + complete §17 spread/position/edge catalogs + empty memory/recurrence shells + typed errors** only. No scoring yet.

### Allowed files (create)

- `lib/features/tarot/narrative/evidence/**` (models, grounding, spread semantics, errors)
- matching tests under `test/features/tarot/narrative_evidence/`
- docs pointer updates only if needed

### Forbidden

- Any change to user reading path / InterpretationEngine / AI executors / payments / profiles keywordIds / ontology constants content / Phase 2 corpus
- Scoring / builder full pipeline / AI / memory providers
- `release/ios-1.0`

### Gates

- `flutter analyze` clean on new surface
- Unit tests for grounding + spread lookup + empty placeholders + errors
- `git diff` shows no unrelated production
- Full Flutter if any shared type touched

### Stop

When 3D.1A tests green — **STOP**; do not start 3D.1B without review.

---

## Appendix A — Classical spreads summary

See **§17** (ACTIVE 3D.0.1): 5 spreads · 26 position rows · 29 edges · weights all 1.0.
Keys exactly as 	arot_spread_positions.dart.


## Appendix B — Question kinds summary

`decision` · `relationship` · `guidance` · `open`
(from `ReadingAskKind`)

## Appendix C — Relationship kinds summary

`support` · `reinforcement` · `contrast` · `conflict` · `causeEffect` · `blockage` · `resolution` · `escalation` · `softening` · `themeRepetition` (current-spread echo only)
