# Signature Spreads — Implementation Spec (Phase 5.0 LOCK)

**Status:** DESIGN LOCKED — Phase 5.0 forensic complete  
**Date:** 2026-09-23  
**Companion audit:** `SIGNATURE_SPREADS_SOURCE_AUDIT.md`  
**Phase 3:** FROZEN — do not modify scorer / selector / builder / profiles / ontology  
**Phase 4:** FROZEN — do not modify eligibility / recurrence / enricher contracts  
**Live Narrative V2:** NOT WIRED  
**OPEN PHASE 5.0 DESIGN DECISIONS:** **0 BLOCKER · 0 MAJOR**

---

## 0 — Non-negotiables

1. Signature Spreads make readings feel like **different professional products**, not “same engine with different card counts”.  
2. Structural spread meaning is **deterministic before AI**.  
3. Phase 3 evidence algorithms stay frozen — Phase 5 **adds** definitions/edges/copy, never rewrites scorer/selector/builder.  
4. Phase 4 recurrence remains card-based — **same spread alone never authorizes recurrence**.  
5. Live user-path wiring of Narrative V2 is **out of Phase 5** (Phase 6+ separately approved).  
6. Do not rename existing `TarotSpreadType` enum **names** or existing `classical.*` spreadIds.  
7. Do not invent a giant spread library — launch set is small and premium.

---

## 1 — Architecture (LOCKED)

### 1.1 Separation of concerns

| Layer | Owns | Does not own |
|---|---|---|
| **A. Identity** | `spreadId`, `version`, `legacyTypeName`, `runtimeEnumName` | UI widgets |
| **B. Product copy** | purpose, supported QuestionKinds, display keys | scoring math |
| **C. Ritual** | `cardCount`, draw slots, completion gate | AI prose |
| **D. Position semantics** | keys, roles, guidingQuestionKeys, weights | network |
| **E. Narrative semantics** | interpretationOrder, arc, synthesis posture | persistence IO |
| **F. Evidence semantics** | maps to frozen `SpreadSemanticDefinition` + authoritative edges | Phase 3 algorithm edits |
| **G. Visual geometry** | `geometryHook`, layout contract | evidence scores |
| **H. Availability** | offeredInPicker, premiumPolicy, feature flags | billing implementation |
| **I. Localization** | all user strings via keys | hardcoded titles |

### 1.2 Canonical model (implementation target)

```text
SignatureSpreadDefinition
  identity:
    spreadId            // e.g. classical.single | signature.crossroads
    version             // int, bump on breaking semantic change
    legacyTypeName      // TarotSpreadType.name when mapped
    runtimeEnumName?    // null only for deferred non-enum signatures
  product:
    purposeKey
    supportedQuestionKinds[]   // open|guidance|relationship|decision
    displayTitleKey
    displayBlurbKey
    bannerKey?
  ritual:
    cardCount
  positions[]:
    positionKey
    index
    role                  // PositionRole (Phase 3 enum — reuse)
    guidingQuestionKey
    displayLabelKey
  narrative:
    interpretationOrder[] // indices
    dominantArcKey
    synthesisStrategyKey  // e.g. single_signal | timeline | field | crossing
    outcomeSlotKey?       // positionKey
    adviceSlotKey?        // positionKey
    uncertaintyPolicyKey  // forbids certainty / absolute future
  evidence:
    classicalSpreadId?    // when identity is classical.*
    edgeTableId           // authoritative edges key = legacyTypeName
  visual:
    geometryHook          // NarrativeGeometryHook / product hook
    lengthBand            // metadata for later prose — not scored
  availability:
    offeredInLivePicker   // bool
    premiumOnly           // bool (default false for launch set)
  recurrencePolicy:
    allowHistoricalContextOverlap   // true (existing Phase 4 rules)
    forbidSameSpreadAloneAuth       // ALWAYS true
    memoryInclusionPosture          // normal | reduced | none
```

**Rule:** Every field above has a named future consumer (ritual UI, evidence builder input, Phase 6 synthesizer, or Visual System). No speculative free-form blobs.

### 1.3 Mapping to frozen Phase 3

`SignatureSpreadDefinition` **projects** into `SpreadSemanticDefinition` for evidence:

- Do not fork scorer/selector/builder.  
- New spreads register: catalog entry + `kAuthoritativePositionEdges` rows.  
- `purposeKey` / `guidingQuestionKey` / `geometryHook` / `lengthBand` remain non-scoring until a later approved consumer exists.

### 1.4 Mapping to runtime ritual

Live ritual continues to use `TarotSpreadType` for draw/session until Phase 5C persistence hardening.

Bridge: `legacyTypeName` ↔ `TarotSpreadType.name` ↔ `ClassicalSpreadSemantics.byLegacyTypeName`.

---

## 2 — Recommended launch set (LOCKED)

**Count: 4 signature products** — three already live classical + one new decision signature.

| # | Product name (EN) | Identity | Cards | Live picker (today → 5A) | Why distinct |
|---|---|---|---|---|---|
| 1 | **Quick Insight** | `classical.single` | 1 | already offered | Single signal; daily/first-session spine |
| 2 | **Timeline** | `classical.threeCard` | 3 | already offered | Temporal arc past→present→direction |
| 3 | **Deep Field** | `classical.fiveCard` | 5 | already offered | Situation / hidden / challenge / support / direction |
| 4 | **Crossroads** | `signature.crossroads` | 5 | **new** (5A+) | Decision fork — option A / option B / tension / counsel / direction |

**Explicitly deferred (not launch):**

| Id | Reason |
|---|---|
| `classical.sevenCard` | Unoffered · preview clamp · weak product differentiation vs Deep Field |
| `classical.celticCross` | Needs true geometry + a11y · high complexity · Visual System phase |
| `signature.the_mirror` / `signature.between_us` (fixtures) | Spec-corpus only · may return in later signature pack after Crossroads ships |

### 2.1 Quick Insight — `classical.single`

| Field | Lock |
|---|---|
| Purpose | One clear reflective signal for the present stance |
| Ideal question | “What should I notice right now?” |
| QuestionKinds | open, guidance |
| Positions | `sign` @0 · role `signal` |
| Interpretation order | `[0]` |
| Relations | none |
| Arc | single_signal |
| Depth | short |
| Outcome/advice slots | `sign` dual-use (signal only — no prediction) |

### 2.2 Timeline — `classical.threeCard`

| Field | Lock |
|---|---|
| Purpose | How the situation moved and where attention opens next |
| Ideal question | “How did I get here, and what opens next?” |
| QuestionKinds | open, guidance, relationship, decision |
| Positions | `past`@0 `root` · `present`@1 `state` · `future`@2 `direction` |
| Interpretation order | `[0,1,2]` |
| Relations | past→present temporal · present→future temporal |
| Arc | timeline |
| Depth | medium |
| Uncertainty | `future` is **direction**, never prophecy |

### 2.3 Deep Field — `classical.fiveCard`

| Field | Lock |
|---|---|
| Purpose | Full-field reading of situation, pressure, resource, and direction |
| Ideal question | “What is really happening beneath this?” |
| QuestionKinds | open, guidance, relationship, decision |
| Positions | `situation`@0 `context` · `hidden_influence`@1 · `challenge`@2 · `strength`@3 `support` · `direction`@4 |
| Interpretation order | `[0,1,2,3,4]` |
| Relations | situation↔challenge pressure · challenge↔strength opposition/support · strength→direction supportive |
| Arc | field |
| Depth | deep |
| Advice slot | `strength` · Outcome/direction slot | `direction` |

### 2.4 Crossroads — `signature.crossroads` (NEW)

| Field | Lock |
|---|---|
| Purpose | Clarify a real choice without fabricating certainty |
| Ideal question | “Which path deserves my next honest step?” |
| QuestionKinds | **decision** (primary), open, guidance |
| Cards | **5** |
| Positions | `option_a`@0 · `option_b`@1 · `tension`@2 `challenge` · `counsel`@3 `support` · `direction`@4 |
| Interpretation order | `[0,1,2,3,4]` |
| Relations | option_a↔option_b opposition · tension↔both pressure · counsel→direction supportive |
| Arc | crossroads |
| Depth | deep |
| Runtime mapping | **new** `TarotSpreadType.crossroads(5)` appended (never rename prior names) **or** interim bridge via fiveCard layout + distinct signature id in Narrative only until 5C — **LOCKED choice: append enum `crossroads` in 5A/5C together** |
| Availability | offered after 5E shadow PASS; not before persistence machine-id |

**Why Crossroads exists:** Deep Field answers “what is happening”; Crossroads answers “which fork”. Same card count, **different roles/edges/arc** → different evidence structure.

---

## 3 — Quality rules (LOCKED)

Signature Spreads MUST NOT:

1. Fabricate certainty or deterministic futures  
2. Imply prophecy via `future` / `direction` / `outcome` labels  
3. Produce identical result section plans for every spread  
4. Treat spread as card count alone  
5. Duplicate generic position meanings across products  
6. Contradict position labels vs roles  
7. Overuse historical memory relative to current spread evidence  
8. Allow historical recurrence to override current spread structure  
9. Expose evidence ids / owner / source ids to users  
10. Require AI to invent structural meaning missing from the definition  

Structural meaning = positions + order + edges + arc keys — deterministic.

---

## 4 — Persistence compatibility (LOCKED)

### 4.1 Write contract (Phase 5C)

| Store | Persist |
|---|---|
| `ReadingSession.spread` | continue enum `.name` |
| `ReadingModel.spreadType` | persist **machine id** = enum `.name` (breaking change from locale label) |
| Dual-read | `TarotSpreadType.fromTitle` remains for all legacy locale titles + aliases |
| Narrative history | keep `classical.*` / future `signature.*` via adapters |

### 4.2 Never rename

- Existing enum names: `single`, `threeCard`, `fiveCard`, `sevenCard`, `celticCross`  
- Existing classical spreadIds and position keys already emitted into history samples  

### 4.3 Append rule

New spreads **append** enum values only. No insert/reorder by renaming.

### 4.4 Reopen

History detail continues to show stored interpretation text. Spread title display uses dual-read parser. Card positionKeys reconstructed from index + definition when missing on journal snapshots.

---

## 5 — Localization contract (LOCKED)

All product strings via keys:

- `tarot.spread.<name>` · `.banner` · `.blurb` · `.purpose`  
- `tarot.pos.<positionKey>` · `tarot.spread.<name>.guide.<positionKey>`  
- TR / EN / RU required before offeredInLivePicker=true  

No hardcoded TR titles on live picker paths.

---

## 6 — Visual geometry contract (LOCKED)

| Spread | Hook | Live layout requirement before offer |
|---|---|---|
| single | `single` | 1-slot center — already OK |
| threeCard | `threeLinear` | 3-slot row — already OK |
| fiveCard | `fiveLinear` | 5-slot row — already OK |
| crossroads | `fiveDecision` | 5-slot with A/B visual grouping (5D/Visual) |
| celticCross | `celticCross` | **deferred** until Visual System |

Preview clamp ≤5 must not silently truncate an offered spread.

---

## 7 — Evidence / recurrence policy (LOCKED)

1. Project signature → `SpreadSemanticDefinition` without changing Phase 3 algorithms.  
2. Register edges in authoritative table keyed by `legacyTypeName`.  
3. Same cards in different spreads **must** produce different position roles/edges → different relationship evidence structure.  
4. Phase 4: `forbidSameSpreadAloneAuth = true` forever.  
5. Memory posture default `normal`; Crossroads may use `reduced` if corpus proves noise (decide in 5E with evidence, not speculation).

---

## 8 — Implementation sequence (LOCKED)

| Phase | Scope | Stop condition |
|---|---|---|
| **5.0** | Forensic + architecture lock (this) | OPEN BLOCKER/MAJOR = 0 |
| **5A** | `SignatureSpreadDefinition` domain + catalog for launch set (classical×3 + Crossroads skeleton) · runtime enum append for `crossroads` **without** live picker yet | Catalog tests green · Phase 3/4 untouched |
| **5B** | Deterministic narrative plan projection → Phase 3 semantics + Crossroads edges · frozen evidence samples (shadow) | Same cards / different spreads differ structurally |
| **5C** | Persistence machine-id write + dual-read · journal positionKey reconstruct · session soft-parse | Old reopen PASS · no enum rename |
| **5D** | Localization + product copy TR/EN/RU · geometry hooks for launch set | No hardcoded live titles |
| **5E** | Shadow integration + frozen signature corpus · picker still behind flag or off | Corpus PASS |
| **5F** | Independent final audit | READY TO FREEZE Phase 5 catalog · still **no** live Narrative V2 |

**Live Narrative V2 wiring = Phase 6 (separate approval).**  
**Celtic / seven live offer = later pack after Visual System.**

---

## 9 — Red-team contracts (BLOCKER-level for implementation)

Implementations MUST fail closed on:

1. Unknown spread id / unparseable persisted title  
2. cardCount ≠ drawn cards  
3. Duplicate `positionIndex` or `positionKey` within a spread  
4. Missing position for an index in interpretationOrder  
5. interpretationOrder length ≠ cardCount or out-of-range indices  
6. Relation edge referencing unknown positionKey  
7. QuestionKind outside `supportedQuestionKinds` when strict mode enabled (Crossroads primary = decision)  
8. Current cards empty / mismatched  
9. Missing required l10n keys for offered spreads  
10. History reopen crash on legacy locale titles  
11. Same-spread-alone recurrence authorization  
12. Non-deterministic catalog ordering  
13. Evidence id / owner / source leakage into UI models  
14. Certainty language in guiding questions / purpose copy  
15. Offering celtic/seven before geometry + persistence ready  
16. Renaming existing enum names  
17. Phase 3 scorer/selector/builder edits  
18. Phase 4 eligibility/H7/H19 edits  
19. Live Narrative V2 wire without Phase 6 approval  
20. Preview clamp truncating an offered spread’s slots  

**Red-team contracts count: 20**

---

## 10 — Acceptance for Phase 5A start

- [x] Source audit complete  
- [x] Spec locked with OPEN BLOCKER/MAJOR = 0  
- [x] Launch set = 4  
- [x] Phase 3/4 must-change = NO  
- [x] Live V2 remains NOT WIRED  
- [x] Persistence dual-read strategy locked  
- [x] Implementation sequence locked  

**READY FOR PHASE 5A: YES**
