# Signature Spreads — Implementation Spec (Phase 5.0 + 5.0.1 LOCK)

**Status:** DESIGN LOCKED — Phase 5.0 forensic + **5.0.1 contract hardening**  
**Date:** 2026-09-23  
**Companion audit:** `SIGNATURE_SPREADS_SOURCE_AUDIT.md`  
**Phase 3:** FROZEN — do not modify scorer / selector / builder / profiles / ontology / `NarrativeGeometryHook`  
**Phase 4:** FROZEN — do not modify eligibility / recurrence / enricher contracts  
**Live Narrative V2:** NOT WIRED  
**OPEN PHASE 5 DESIGN DECISIONS:** **0 BLOCKER · 0 MAJOR**

---

## 0 — Non-negotiables

1. Signature Spreads make readings feel like **different professional products**, not “same engine with different card counts”.  
2. Structural spread meaning is **deterministic before AI**.  
3. Phase 3 evidence algorithms stay frozen — Phase 5 **adds** definitions/edges/copy, never rewrites scorer/selector/builder.  
4. Phase 4 recurrence remains card-based — **same spread alone never authorizes recurrence**.  
5. Live user-path wiring of Narrative V2 is **out of Phase 5** (Phase 6+ separately approved).  
6. Do not rename existing `TarotSpreadType` enum **names** or existing `classical.*` spreadIds.  
7. Do not invent a giant spread library — launch set is small and premium.  
8. **Phase 5A MUST NOT modify `TarotSpreadType`.** Enum append for Crossroads is **5D only**, after TR/EN/RU keys exist.  
9. **Do not add** `fiveDecision` (or any product geometry) to frozen `NarrativeGeometryHook`. Phase 5 owns `SignatureGeometryHook`.

---

## 1 — Architecture (LOCKED)

### 1.1 Separation of concerns

| Layer | Owns | Does not own |
|---|---|---|
| **A. Identity** | `spreadId`, `version`, `runtimeEnumName` | UI widgets |
| **B. Product copy** | purpose, QuestionKinds, display keys | scoring math |
| **C. Ritual** | `cardCount`, draw slots | AI prose |
| **D. Position semantics** | keys, roles, guidingQuestionKeys, labels | network |
| **E. Narrative semantics** | interpretationOrder, arc, synthesis | persistence IO |
| **F. Evidence semantics** | projection to frozen Phase 3 + edges | Phase 3 algorithm edits |
| **G. Visual** | `SignatureGeometryHook`, lengthBand metadata | Phase 3 geometry enum |
| **H. Availability** | offeredInLivePicker, premiumOnly | billing implementation |
| **I. Localization** | all user strings via keys | hardcoded titles |

### 1.2 Canonical `SignatureSpreadDefinition` (exact field lock)

```text
SignatureSpreadDefinition
  IDENTITY
    spreadId              // classical.* | signature.*
    version               // int >= 1
    runtimeEnumName       // TarotSpreadType.name when bridged; metadata-only until 5D

  PRODUCT
    purposeKey
    supportedQuestionKinds[]   // subset of open|guidance|relationship|decision
    primaryQuestionKind        // MUST ∈ supportedQuestionKinds
    displayTitleKey
    displayBlurbKey
    bannerKey?                 // optional

  RITUAL
    cardCount                  // > 0

  POSITIONS[]                  // length == cardCount
    positionKey                // non-empty, unique in spread
    index                      // unique, contiguous 0..cardCount-1
    role                       // existing PositionRole only — no new Phase 3 values
    guidingQuestionKey
    displayLabelKey

  NARRATIVE
    interpretationOrder[]      // length == cardCount; each index once
    dominantArcKey
    synthesisStrategyKey
    outcomeSlotKey?            // must reference a positionKey when non-null
    adviceSlotKey?             // must reference a positionKey when non-null
    uncertaintyPolicyKey

  EVIDENCE
    projectionSpreadId         // frozen SpreadSemanticDefinition.spreadId target
    edgeTableId                // authoritative edges key (legacyTypeName / runtimeEnumName)

  VISUAL
    signatureGeometryHook      // SignatureGeometryHook — Phase 5 ONLY
    lengthBand                 // metadata for later prose — not scored

  AVAILABILITY
    offeredInLivePicker
    premiumOnly

  RECURRENCE
    allowHistoricalContextOverlap
    forbidSameSpreadAloneAuth  // MUST be true for launch catalog
    memoryInclusionPosture     // normal | reduced | none
```

No free-form / speculative fields.

### 1.3 Geometry type separation (5.0.1 LOCK)

Frozen Phase 3:

```text
NarrativeGeometryHook { singlePoint, linearRow, celticCross }
```

Phase 5 product-owned (new in 5A — **not** Phase 3):

```text
SignatureGeometryHook { single, threeLinear, fiveLinear, fiveDecision }
```

| Signature product | SignatureGeometryHook | Phase 3 NarrativeGeometryHook projection |
|---|---|---|
| Quick Insight | `single` | `singlePoint` |
| Timeline | `threeLinear` | `linearRow` |
| Deep Field | `fiveLinear` | `linearRow` |
| Crossroads | `fiveDecision` | `linearRow` |

Phase 3 geometry remains **non-scoring metadata**. Crossroads may project to `linearRow` for frozen evidence while product/UI later uses `fiveDecision`.

### 1.4 Mapping to frozen Phase 3

`SignatureSpreadDefinition` **projects** into `SpreadSemanticDefinition`:

- Do not fork scorer / selector / builder.  
- New spreads register catalog projection + `kAuthoritativePositionEdges` rows (5B).  
- Reuse existing `PositionRole` values only.

### 1.5 Runtime enum timing (5.0.1 LOCK)

| Phase | `TarotSpreadType` | Crossroads reachability |
|---|---|---|
| **5A** | **unchanged** | catalog metadata `runtimeEnumName: 'crossroads'` only · `offeredInLivePicker: false` |
| **5B** | unchanged | shadow projection only |
| **5C** | unchanged | l10n + product geometry · still unreachable |
| **5D** | **append** `crossroads(5)` at **END** after TR/EN/RU keys exist | runtime bridge · picker still **false** |
| **5E–5F** | as 5D | picker remains **false** through 5F |

Reason: `TarotSpreadType.label` resolves `tarot.spread.$name` immediately — enum before l10n creates incomplete runtime surface.

---

## 2 — Launch catalog (LOCKED · deterministic order)

1. `classical.single` — **Quick Insight**  
2. `classical.threeCard` — **Timeline**  
3. `classical.fiveCard` — **Deep Field**  
4. `signature.crossroads` — **Crossroads**

### 2.1 Quick Insight — `classical.single`

| Field | Lock |
|---|---|
| version | 1 |
| runtimeEnumName | `single` |
| cardCount | 1 |
| primaryQuestionKind | open |
| supported | open, guidance |
| positions | `sign`@0 · `PositionRole.signal` |
| interpretationOrder | `[0]` |
| SignatureGeometryHook | `single` |
| Phase 3 geometry projection | `singlePoint` |
| offeredInLivePicker | true (existing live) |
| forbidSameSpreadAloneAuth | true |
| memoryInclusionPosture | normal |

### 2.2 Timeline — `classical.threeCard`

| Field | Lock |
|---|---|
| version | 1 |
| runtimeEnumName | `threeCard` |
| cardCount | 3 |
| primaryQuestionKind | open |
| supported | open, guidance, relationship, decision |
| positions | `past`@0 `root` · `present`@1 `state` · `future`@2 `direction` |
| interpretationOrder | `[0,1,2]` |
| SignatureGeometryHook | `threeLinear` |
| Phase 3 geometry projection | `linearRow` |
| offeredInLivePicker | true (existing live) |
| forbidSameSpreadAloneAuth | true |
| memoryInclusionPosture | normal |
| Uncertainty | `future` = direction, never prophecy |

### 2.3 Deep Field — `classical.fiveCard`

| Field | Lock |
|---|---|
| version | 1 |
| runtimeEnumName | `fiveCard` |
| cardCount | 5 |
| primaryQuestionKind | open |
| supported | open, guidance, relationship, decision |
| positions | `situation`@0 `context` · `hidden_influence`@1 `hiddenInfluence` · `challenge`@2 `challenge` · `strength`@3 `support` · `direction`@4 `direction` |
| interpretationOrder | `[0,1,2,3,4]` |
| adviceSlotKey | `strength` |
| outcomeSlotKey | `direction` |
| SignatureGeometryHook | `fiveLinear` |
| Phase 3 geometry projection | `linearRow` |
| offeredInLivePicker | true (existing live) |
| forbidSameSpreadAloneAuth | true |
| memoryInclusionPosture | normal |

### 2.4 Crossroads — `signature.crossroads` (exact 5.0.1 lock)

| Field | Lock |
|---|---|
| version | **1** |
| runtimeEnumName | `crossroads` (**metadata only until 5D**) |
| cardCount | **5** |
| primaryQuestionKind | **decision** |
| supported | **decision · open · guidance** |
| relationship | **UNSUPPORTED** — do not silently remap |
| offeredInLivePicker | **false** through **5F** |
| premiumOnly | false |
| memoryInclusionPosture | **normal** initially — do not reduce before corpus evidence |
| forbidSameSpreadAloneAuth | **true** |
| allowHistoricalContextOverlap | **true** |
| SignatureGeometryHook | **fiveDecision** |
| Phase 3 geometry projection | **linearRow** |
| interpretationOrder | `[0,1,2,3,4]` |
| adviceSlotKey | `counsel` |
| outcomeSlotKey | `direction` |
| dominantArcKey | `crossroads` |
| synthesisStrategyKey | `crossroads` |
| uncertaintyPolicyKey | reflective next-step only — never deterministic future |

#### Crossroads positions (exact)

| index | key | role |
| ---: | --- | --- |
| 0 | `option_a` | `PositionRole.direction` |
| 1 | `option_b` | `PositionRole.direction` |
| 2 | `tension` | `PositionRole.challenge` |
| 3 | `counsel` | `PositionRole.support` |
| 4 | `direction` | `PositionRole.direction` |

Rationale: A/B are candidate paths (direction), not current-state context. A/B conflict is **edge-level** opposition, not role-level. Final `direction` is reflective orientation — not prophecy. **No new Phase 3 PositionRole values.**

#### Crossroads edges (exact · Phase 5B · count = 4)

| # | Endpoints | directed | edgeKind |
|---|---|---|---|
| 1 | `option_a` ↔ `option_b` | false | `opposition` |
| 2 | `tension` ↔ `option_a` | false | `pressure` |
| 3 | `tension` ↔ `option_b` | false | `pressure` |
| 4 | `counsel` → `direction` | true | `supportive` |

**No additional Crossroads edges in 5B** unless a later explicit phase changes this lock.

Compatible with frozen Phase 3: opposition + challenge/avoid drives conflict kinds; pressure softens; supportive feeds resolution — all existing scorer paths.

**Why Crossroads exists:** Deep Field = “what is happening”; Crossroads = “which fork”. Same card count, different roles/edges/arc → different evidence structure.

**Deferred (not launch):** `classical.sevenCard`, `classical.celticCross`, fixture `signature.the_mirror` / `signature.between_us`.

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
11. Silently reinterpret `relationship` questions as Crossroads  

---

## 4 — Persistence compatibility (LOCKED · Phase 5D)

| Store | Persist |
|---|---|
| `ReadingSession.spread` | enum `.name` |
| `ReadingModel.spreadType` | machine id = enum `.name` (dual-read legacy locale titles) |
| Narrative history | `classical.*` / `signature.*` via adapters |

Never rename existing enum names. Append only. Soft/fail-closed unknown persisted values. Reconstruct missing journal `positionKey` from index + definition.

---

## 5 — Localization contract (LOCKED · Phase 5C)

All product strings via keys · TR/EN/RU required before any offered picker / before Crossroads enum append (5D).

Keys include: titles · blurbs · purposes · position labels · guiding questions.

---

## 6 — Evidence / recurrence policy (LOCKED)

1. Project signature → `SpreadSemanticDefinition` without changing Phase 3 algorithms.  
2. Register exact Crossroads edges (table above) in 5B.  
3. Same cards in Deep Field vs Crossroads **must** produce structurally distinct evidence.  
4. `forbidSameSpreadAloneAuth = true` forever for launch catalog.  
5. Crossroads memory posture stays **normal** until corpus evidence justifies change.

---

## 7 — Implementation sequence (5.0.1 LOCKED)

| Phase | Scope | Forbidden |
|---|---|---|
| **5.0 / 5.0.1** | Forensic + hardened contracts (docs) | production code |
| **5A** | Pure `SignatureSpreadDefinition` + Phase 5-only enums (`SignatureGeometryHook`, …) + deterministic launch catalog with exact roles/kinds/arcs · Crossroads `runtimeEnumName` inert · `offeredInLivePicker=false` | `TarotSpreadType` changes · Phase 3/4 · picker · persistence · l10n · live V2 |
| **5B** | Signature → frozen `SpreadSemanticDefinition` projection · exact 4 Crossroads edges · validation · frozen structural samples · Deep Field vs Crossroads distinctness | Phase 3 algorithm edits · picker · enum append |
| **5C** | TR/EN/RU product copy · SignatureGeometryHook descriptors | enum append preferred deferred · Crossroads still unreachable · live V2 |
| **5D** | After 5C keys exist: append `TarotSpreadType.crossroads(5)` at END · machine-id write · dual-read · soft unknown · positionKey reconstruct · Crossroads runtime bridge · picker still false | rename/reorder enums · live V2 |
| **5E** | Shadow + frozen signature corpus · Crossroads picker disabled · regressions | live V2 |
| **5F** | Independent final audit → Phase 5 freeze candidate | live V2 (Phase 6) |

---

## 8 — Domain / catalog validation locks (5A+)

5A implements pure validation (no l10n/runtime IO):

- spreadId non-empty + unique  
- version ≥ 1  
- cardCount > 0  
- positions.length == cardCount  
- position index unique + contiguous `0..cardCount-1`  
- positionKey non-empty + unique  
- interpretationOrder.length == cardCount · each index exactly once  
- supportedQuestionKinds non-empty  
- primaryQuestionKind ∈ supportedQuestionKinds  
- outcomeSlotKey / adviceSlotKey reference real positions when non-null  
- runtimeEnumName non-empty when supplied  
- catalog spreadIds unique  
- catalog runtimeEnumNames unique when non-null  
- `forbidSameSpreadAloneAuth == true` for launch catalog  
- deterministic catalog order  

Later stages add: offered spread must have required l10n/geometry before `offeredInLivePicker=true`.

---

## 9 — Red-team contracts (BLOCKER-level)

1. Unknown spread id / unparseable persisted title  
2. cardCount ≠ drawn cards  
3. Duplicate positionIndex / positionKey  
4. Missing position for interpretationOrder index  
5. Bad interpretationOrder  
6. Edge referencing unknown positionKey  
7. QuestionKind outside supported (esp. relationship → Crossroads)  
8. Current cards mismatched  
9. Missing required l10n for offered spreads  
10. History reopen crash on legacy titles  
11. Same-spread-alone recurrence  
12. Non-deterministic catalog order  
13. Evidence/owner/source leakage  
14. Certainty language in copy  
15. Offering celtic/seven before geometry+persistence ready  
16. Renaming existing enum names  
17. Phase 3 scorer/selector/builder edits  
18. Phase 4 H7/H19/eligibility edits  
19. Live Narrative V2 without Phase 6 approval  
20. Preview clamp truncating offered slots  
21. `TarotSpreadType.crossroads` before TR/EN/RU keys  
22. Adding product geometry to frozen `NarrativeGeometryHook`  
23. Extra Crossroads edges beyond the locked 4 in 5B  

**Red-team contracts count: 23**

---

## 10 — Acceptance for Phase 5A

- [x] Source audit complete  
- [x] 5.0.1 Crossroads roles / edges / QuestionKinds locked  
- [x] SignatureGeometryHook separated from Phase 3  
- [x] Enum append deferred to 5D  
- [x] Implementation sequence reordered  
- [x] OPEN BLOCKER/MAJOR = 0  
- [x] Phase 3/4 must-change = NO  
- [x] Live V2 NOT WIRED  

**READY FOR PHASE 5A: YES**
