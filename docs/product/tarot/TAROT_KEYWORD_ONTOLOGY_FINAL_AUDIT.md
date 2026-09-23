# TAROT — Keyword Ontology Final Audit (Phase 3C.5F)

**Phase:** 3C.5F — independent auditor mode  
**Start SHA:** `dca0cc197b7ea02f1715431de5edbfc655bc48a6`  
**Authority reviewed:** Phase 3C.5D.1 plan + Phase 3C.5E implementation  
**Production code modified during audit:** **NO**  
**Audit date:** 2026-09-23  

---

## Verdict (two separate results)

| Result | Value |
|---|---|
| **PHASE 3C.5F AUDIT** | **PASS** (audit completed; production untouched) |
| **DECK READY FOR EVIDENCE ENGINE** | **YES** |
| **FR-M04** | **RESOLVED** |

Readiness is granted **only** under the Evidence Engine safeguards in §S. Soft keyword overlap alone must never conclude relatedness, recurrence, or mind-reading.

---

## A — Implementation integrity (recomputed from production)

Independent recompute from `NarrativeTarotProfileCatalog` / profile sources + `NarrativeKeywordIds`:

| Metric | Expected | Observed | Status |
|---|---:|---:|---|
| Profiles | 78 | 78 | PASS |
| Orientations | 156 | 156 | PASS |
| Ontology revision | 1 | 1 | PASS |
| Defined canonical ids | 128 | 128 | PASS |
| Used ids | 122 | 122 | PASS |
| Assignments | 439 | 439 | PASS |
| Singleton ids | 30 | 30 | PASS |
| Singleton % | ≈24.59 | 24.59 | PASS |
| Avg upright | ≈2.76 | 2.76 | PASS |
| Avg reversed | ≈2.87 | 2.87 | PASS |
| Outside 2–4 | 0 | 0 | PASS |
| Duplicate ids in orientation | 0 | 0 | PASS |
| Identical upright/reversed sets | 0 | 0 | PASS |
| Non-canonical production ids | 0 | 0 | PASS |
| Unsafe ids | 0 | 0 | PASS |
| Frozen fixture equality | 156/156 | 156/156 | PASS |

Fixture: `test/fixtures/tarot_keyword_ontology_v1.json`  
Tests: `test/features/tarot/narrative_domain/narrative_keyword_ontology_v1_test.dart`

---

## B — Production diff forensics (`a0dbee28` → `dca0cc19`)

**Lib files changed:** 79 = 78 profiles + `narrative_keyword_ids.dart`.

**Non-keyword fingerprint drift (profiles):** **0**.

Confirmed profile deltas are only:

- `import '../../domain/narrative_keyword_ids.dart';`
- `keywordIds` remapped to `NarrativeKeywordIds.*`

**Unchanged:** coreMeaning, light, shadow, tension, desire, fear, relationshipDynamic, decisionDynamic, actionDirection, upright/reversed.expression, reversed.transforms, symbolTags, profileRevision, canonicalCardId.

**No other production source** outside ontology module + 78 profiles.

**Diff forensics:** **PASS**

---

## C — Full 156-orientation semantic audit

Method: for every orientation, compare keywordIds to EN upright/reversed expression, card shadow/light where relevant, transforms, and canonical meaning (via authored Narrative profiles). Appendix B equality alone was **not** treated as sufficient.

### Classification totals

| Class | Count |
|---|---:|
| FAITHFUL | 118 |
| FAITHFUL-WITH-COMPRESSION | 38 |
| QUESTIONABLE | 0 |
| SEMANTIC-LOSS | 0 |
| SEMANTIC-INVERSION | 0 |

Compression examples (acceptable): multi-prose nuances folded into 2–3 atoms (`opening`/`holding`, `roots`/`clarity`, court Page messenger clusters) without polarity flip.

**Unsupported keyword concepts (concepts absent from prose + orientation + card meaning):** **0**

---

## D — 3C.5D.1 repair sentinels

| Orientation | Keywords | Expression support | Class |
|---|---|---|---|
| wands_08 upright | momentum, messenger, flow | measured flow / arrows in air | FAITHFUL |
| swords_12 upright | momentum, communication, clarity | directed speed carries thought | FAITHFUL |
| pentacles_02 upright | coordination, balance, focus | living rhythm / two weights | FAITHFUL |
| major_11 upright | balance, truth, accountability | standards + honest responsibility | FAITHFUL |
| major_14 upright | balance, integration, restraint | patient integration / blend | FAITHFUL |
| wands_13 reversed | control, envy, withdrawal | control, envy, or dimming | FAITHFUL |
| major_04 reversed | rigidity, control, instability | overcontrol / boundaries fail | FAITHFUL |
| major_10 reversed | resistance, delay, instability | delayed / prolonged / misread | FAITHFUL |
| cups_02 reversed | imbalance, projection, haste | projection / rush a merge | FAITHFUL |
| cups_13 reversed | overflow, boundary, rescue | excess rescue / deficiency of boundary | FAITHFUL |

All sentinels: **PASS**

---

## E — Polarity / state separation

| Pair | Both present in ontology | Collapse found in mappings? |
|---|---|---|
| balance / imbalance | YES | NO — Justice/Temperance/Pentacles 2 keep balance; reversed imbalance retained |
| stability / instability | YES | NO — antonyms remain distinct ids |
| momentum / haste | YES | NO — upright speed ≠ haste |
| belonging / isolation | YES | NO |
| abundance / scarcity | YES | NO |
| nurture / rescue | YES | NO — Cups Queen reversed uses rescue, not nurture |
| joy vs withdrawn/diminished | joy kept; diminished→withdrawal | NO false joy grouping |
| union vs premature union | union upright; haste/projection for rushed merge | NO hastyUnion→union |
| clarity / confusion | YES | NO |
| boundary / coldness | YES | NO |
| pause / delay | YES | NO — pause ≠ delay |

**Polarity gate:** **PASS**

---

## F — False overlap audit

Multi-keyword overlaps (≥2 shared ids): **54** pairs.

### Highest-risk reviewed pairs

| Pair | Shared | Human judgment |
|---|---|---|
| wands_11 upright ↔ pentacles_11 upright | curiosity, learning, messenger (3) | Real Page archetype rhyme; **soft false-similarity risk** if engine treats 3-hit as strong relatedness. Suit/prose still distinguish. **NON-BLOCKING** with safeguard. |
| swords_11 reversed ↔ swords_12 reversed | harshSpeech, haste, notListening (3) | Adjacent court shadow rhyme; prose differs (Page vs Knight). **NON-BLOCKING** with safeguard. |
| Many haste+scatter reversed pairs | haste, scatter | Same difficult-dynamic atom across cards — **COHERENT** soft theme, not false “same card.” |
| cups_02 rev ↔ major_14 rev | haste, imbalance | Related excess/imbalance theme only — not identity. OK soft. |

**Human-reviewed high-risk pairs:** 12 (all ≥2 shares involving Pages/courts or 3-share pairs + top HF co-occurrence samples).  
**Confirmed engine-blocking false overlaps:** **0** (given §S safeguards).

---

## G — High-frequency keywords (5+)

**Reviewed:** 33 ids with count ≥5.

Top (≥8): scatter(14), haste(13), withdrawal(13), escape(10), isolation(9), control(9), delay(9), display(8), fear(8).

| Class | Count | Notes |
|---|---:|---|
| COHERENT | 24 | Same atom across uses |
| BROAD-BUT-USABLE | 9 | scatter/haste/withdrawal/escape/delay/fear/control/display/isolation — recurring difficult dynamics; must be **low discriminative weight** |
| OVER-GENERIC | 0 | None blocked readiness |
| MISMERGED | 0 | Required |

---

## H — Singleton audit (30/30)

All 30 singletons reviewed.

| Class | Count | Examples |
|---|---:|---|
| JUSTIFIED-DISTINCT | 28 | envy, coordination, externalDemand, pressure, receptivity, principle, … |
| COULD-MERGE-BUT-NOT-NEEDED | 2 | teaching/tradition (both Major 5 upright — kept distinct deliberately) |
| SUSPICIOUS-FRAGMENTATION | 0 | — |

Envy singleton remains correct (symbolic only; never mind-reading).

---

## I — Unused canonical ids (6)

Defined 128 − used 122 = **6 unused**:

| Id | Classification | Notes |
|---|---|---|
| `dependence` | INTENTIONAL-RESERVED | Available for future attachment excess; unused after repair |
| `enthusiasm` | INTENTIONAL-RESERVED | Optional Wands vitality flavor not required by Appendix B |
| `internalStrain` | INTENTIONAL-RESERVED | Pressure-split option; no card needed it |
| `labor` | INTENTIONAL-RESERVED | Pentacles work nuance covered by craft/stewardship |
| `listening` | INTENTIONAL-RESERVED | Distinct from notListening; no upright assignment this revision |
| `misdirection` | INTENTIONAL-RESERVED | Exists as **transform**; kept as keyword id for possible future content use |

No STALE-DESIGN-LEFTOVER creating contract ambiguity beyond documenting reserved status.  
**Do not delete in this phase.** INFO only.

---

## J — Orientation signal

- Identical upright/reversed keyword sets: **0**
- Human semantic orientation collapses: **0**
- Reversed sets are not mere synonym restatements of upright; transforms remain separate mechanism layer.

---

## K — Transform layer dual-use

Orientations with keyword ∩ transform-name: **14**.

Allowed content duals observed: `delay`, `avoidance`, `release`.

All 14 retain ≥1 non-transform content keyword.

| Class | Count |
|---|---:|
| VALID-DUAL-LAYER | 14 |
| REDUNDANT | 0 |
| ENGINE-RISK | 0 |

**Transform dual-layer:** **PASS**

Note: keyword `release` on major_12 reversed names *content* (necessary release resisted) while transforms are `delay` + `blockedExpression` — complementary, not double-count of the same mechanism.

---

## L — Symbol tag interaction

Rows where `symbolTags ∩ keywordIds` nonempty: **64** (expected; tags and keywords share vocabulary by design).

| Interaction | Assessment |
|---|---|
| Useful complementarity | Tags = sparse relation/theme; keywords = orientation atoms |
| Redundant duplicates | Same string can appear in both layers |
| Double-count risk | **YES** if engine sums identical strings across layers |

**Required Evidence Engine safeguard:** never add keyword score + symbolTag score for the **same id string** on the same card without dedupe / single-channel credit.

**Symbol-tag interaction:** **CONCERNS** (non-blocking; contract must enforce dedupe)

---

## M — Suit identity

| Suit | Assessment |
|---|---|
| Wands | Retains spark/direction/will/scatter/haste/display — not collapsed to momentum alone |
| Cups | Retains belonging/flow/overflow/intimacy/holding — not emotion blob |
| Swords | Retains clarity/inquiry/harshSpeech/mindBurden — not conflict-only |
| Pentacles | Retains structure/stewardship/stability/scarcity — not stability-only |
| Majors | Archetypal ids retained (threshold, agency, ending, integration, …) |

**Suit identity:** **PASS** (watchpoint: Page keyword rhyme — see findings)

---

## N — Rank identity

Cross-suit same-rank upright keyword shares: **11** pairs (mostly 1 shared soft atom).

No forced Ace→Ten taxonomy. No artificial rank collapse requiring engine block.

**Rank identity:** **PASS / NON-BLOCKING CONCERNS** (light cross-suit rhyme only)

---

## O — Court identity

Pages upright sets:

| Court | Keywords |
|---|---|
| Wands Page | messenger, learning, curiosity |
| Cups Page | messenger, curiosity, receptivity |
| Swords Page | messenger, learning, inquiry |
| Pentacles Page | learning, curiosity, messenger |

Unique sets: **3 distinct** (Wands Page == Pentacles Page as **sets**).  
Inquiry vs curiosity preserved on Swords vs Cups.  
No Page=inferior / King=superior encoding. No gender stereotype ids.

Knights/Queens/Kings remain differentiated within suits.

**Court identity:** **CONCERNS** (Wands/Pentacles Page set identity) — **NON-BLOCKING** with §S multi-signal + suit veto.

---

## P — Relationship with authored prose

Spot + systematic review: keywords summarize orientation expression; no migration orphans unsupported by prose/canonical meaning.

**Unsupported keyword concepts:** **0**

**Canonical fidelity:** **PASS**

---

## Q — Safety

Ontology + assignments reviewed for accusation/certainty patterns. Special ids:

| Id | Safety reading |
|---|---|
| envy | Symbolic comparison/jealousy theme only — no “they envy you” |
| projection | Inner-to-outer mechanism — not accusation |
| fear | Symbolic anticipatory dread — not diagnosis |
| attachment | Bond dynamics — not destiny/soulmate |
| control | Grip/overcontrol theme — not criminal |
| rescue | Over-saving dynamic — not medical |
| bondage | Constraint theme — not legal certainty |

Unsafe ids in ontology/profiles: **0**

**Safety:** **PASS**

---

## R — Evidence Engine use contract

**READY** — soft evidence only.

Allowed: theme overlap candidate · relationship candidate scoring · similarity hint · question relevance hint.

Forbidden: single-keyword conclusion · prediction · mind-reading · recurrence authority · overriding prose/position/orientation · overriding deterministic recurrence facts.

---

## S — Required future Evidence Engine safeguards (acceptance constraints)

1. One shared keyword **cannot** establish relationship or theme certainty.  
2. Multiple **independent** signals required (keywords + transforms + prose anchors + position + canonical relations).  
3. High-frequency ids (scatter/haste/withdrawal/…) carry **lower discriminative weight**.  
4. Identical id across **keywordIds** and **symbolTags** must be **deduped** (no blind double-count).  
5. Orientation is an independent gate.  
6. Transforms are mechanism signals, not keyword substitutes.  
7. Spread position remains independent evidence.  
8. Canonical card relationships remain independent evidence.  
9. Contradiction (prose/orientation/position) can outweigh overlap.  
10. Keyword overlap **never** creates recurrence claims.  
11. Suit identity is an independent veto/weight — especially when Page soft sets rhyme.  
12. `envy` / `projection` / `fear` / `control` remain symbolic — never mind-reading or accusation templates.

---

## T — Prior FR / RT final status

| ID | Status |
|---|---|
| FR-B01 | RESOLVED |
| FR-M01 | RESOLVED |
| FR-M02 | RESOLVED |
| FR-M03 | RESOLVED |
| FR-M04 | **RESOLVED** (this audit) |
| RT-M01 | RESOLVED |
| RT-M02 | RESOLVED |
| RT-M03 | RESOLVED — NON-BLOCKING MINORS REMAIN |

Regression spot-checks (prose unchanged in 3C.5E): cups_09 vs cups_10 · cups_03 vs cups_10 decision · shadow vs reversed courts · Magician desire · Swords 9 / Cups 10 naturalness — **no regression introduced by keyword remap**.

---

## U — Remaining non-blocking minors

| ID | Description | Engine class |
|---|---|---|
| FR-m01 | RU contrast scaffold residual | NON-BLOCKING FOR EVIDENCE ENGINE |
| FR-m02 | EN “Quietly, one may seek” desire opener | NON-BLOCKING FOR EVIDENCE ENGINE |
| FR-m03 | cups_09 “enough” nouning | NON-BLOCKING FOR EVIDENCE ENGINE |
| FR-m04 | swords_10 compound craft | NON-BLOCKING FOR EVIDENCE ENGINE |
| FR-F01 | Wands Page / Pentacles Page upright keyword set identity | NON-BLOCKING FOR EVIDENCE ENGINE (safeguard §S.11) |
| FR-F02 | Swords Page / Knight reversed keyword set identity | NON-BLOCKING FOR EVIDENCE ENGINE (safeguard §S.11) |
| FR-F04 | keyword∩symbolTag same-string double-count risk | NON-BLOCKING FOR EVIDENCE ENGINE (safeguard §S.4) |

---

## V — Findings register

### BLOCKER — 0

### MAJOR — 0

### MINOR — 3

#### FR-F01 — Wands/Pentacles Page upright keyword identity

- **Severity:** MINOR  
- **Cards:** wands_11 upright, pentacles_11 upright  
- **Keywords:** curiosity, learning, messenger  
- **Evidence:** identical sets; expressions still suit-distinct (fire messenger vs learning hand/merchant caution)  
- **Why it matters:** naive 3-hit soft scoring could over-relate Pages across suits  
- **Engine impact:** must apply suit veto + multi-signal rule  
- **Direction:** keep data; enforce §S; optional future suit-tint keyword only if Evidence Engine still overfires after weighting  

#### FR-F02 — Swords Page/Knight reversed keyword identity

- **Severity:** MINOR  
- **Cards:** swords_11 reversed, swords_12 reversed  
- **Keywords:** harshSpeech, haste, notListening  
- **Evidence:** identical sets; rank prose still differs  
- **Engine impact:** same as FR-F01 within-suit rank discrimination  
- **Direction:** keep; weight down HF speech/haste cluster; require non-keyword signals  

#### FR-F04 — Keyword / symbolTag channel overlap

- **Severity:** MINOR  
- **Evidence:** 64 orientations with nonempty tag∩keyword  
- **Engine impact:** double-count if summed naively  
- **Direction:** dedupe by id string across layers  

### INFO — 2

#### FR-F03 — Six unused canonical ids

- **Severity:** INFO  
- **Ids:** dependence, enthusiasm, internalStrain, labor, listening, misdirection  
- **Class:** INTENTIONAL-RESERVED  
- **Direction:** document; do not delete in audit  

#### FR-F05 — HF difficult-dynamics concentration

- **Severity:** INFO  
- **Evidence:** scatter/haste/withdrawal dominate top counts  
- **Class:** BROAD-BUT-USABLE  
- **Direction:** low weight in Evidence Engine scoring  

---

## Readiness decision

| Gate | Result |
|---|---|
| BLOCKER | 0 |
| MAJOR | 0 |
| FR-B01..M03 | RESOLVED |
| FR-M04 | RESOLVED |
| RT-M01..M03 | RESOLVED |
| Semantic inversion | 0 |
| Semantic loss | 0 |
| Unsupported keyword concepts | 0 |
| Orientation collapse | 0 |
| Unsafe ontology | 0 |
| Engine-blocking false overlap | 0 |
| Engine usage contract | READY |
| Canonical fidelity | PASS |

**DECK READY FOR EVIDENCE ENGINE: YES**

Next: ChatGPT review before Narrative Evidence Engine **implementation specification** (not coding until reviewed).

Narrative Evidence Engine: **NOT IMPLEMENTED**  
Runtime Narrative V2: **NOT USER-REACHABLE**  
Visual System: **NOT IMPLEMENTED**

---

## Machine companions (audit-only; not production)

- `tool/qa/phase3c5f_audit.py`
- `tool/qa/phase3c5f_audit_data.json`
- `tool/qa/phase3c5f_prod_metrics.json`
