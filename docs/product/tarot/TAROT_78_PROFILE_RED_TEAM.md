# TAROT 78 PROFILE RED-TEAM

**Phase:** 3C — 78-card cross-deck semantic red-team  
**Date:** 2026-09-22  
**Start HEAD:** `c2b5a6d8fa54fe17ba8c000b536d5e3f5a689f01`  
**Scope:** Audit + test-only diagnostics. **No profile content modified.**

---

## Executive result

| Gate | Result |
|---|---|
| AUDIT STATUS | **PASS** (78/78 reviewed; metrics + evidence-backed findings) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| BLOCKERS | **0** |
| MAJOR | **3** |
| MINOR | **6** |
| INFO | **5** |

Upright card identities are largely **faithful** to the ORACLY canonical deck and remain **discriminative across suits and ranks**. The catalog is **not** ready for a Narrative Evidence Engine primarily because:

1. widespread **shadow ≈ reversed.expression** cloning weakens orientation signal  
2. **authoring-template monotony** risks robotic sameness in synthesized prose  
3. a few **near-copy relational/decision** pairs need human remediation before engine consumption  

Safety cross-deck review found **no blockers**. Canonical drift flags from token Jaccard were **false positives** on human review.

---

## Deck-wide metrics

| Metric | Value |
|---|---|
| Profiles reviewed | **78 / 78** |
| Catalog ids == `OraclyTarotDeck.expectedIds` | PASS (preconditioned by Phase 3B4) |
| Exact long-field EN duplicates (≥40 chars, cross-card) | **0** |
| High-similarity candidates (Jaccard ≥0.55, field-level) | **3** pairs reviewed |
| Automated safety regex hits | **0** |
| Locale length-skew candidates | **0** |

### Canonical fidelity (human-resolved)

Automated token overlap vs `symbolicMeaning` initially flagged 9 QUESTIONABLE + 7 CLEAR. Human review cleared **all** of them to FAITHFUL / FAITHFUL-WITH-EXPANSION (majors paraphrase poetic canon into prose without meaning swap).

| Class | Count |
|---|---|
| FAITHFUL | **29** |
| FAITHFUL-WITH-EXPANSION | **49** |
| QUESTIONABLE-DRIFT | **0** |
| CLEAR-DRIFT | **0** |

### ReversedTransformKind distribution (occurrences)

| Transform | Count |
|---|---|
| excess | 37 |
| distortion | 23 |
| misdirection | 18 |
| avoidance | 17 |
| internalization | 15 |
| delay | 14 |
| blockedExpression | 14 |
| deficiency | 9 |
| privateInternal | 8 |
| release | 1 |

Cards with multiple reversed transforms vs single: **majority use 1–2**; uneven distribution is acceptable when justified. **excess** concentration is notable (see RT-M02).

### Template phrase frequency (EN, across all semantic fields)

| Phrase | Approx count |
|---|---|
| “There may be a wish…” | 78 |
| “may slide into…” | 90 |
| “It speaks of…” | 62 |
| “do not…” | 62 |
| “The choice…” | 60 |
| “in a bond…” | 54 |
| “asks to separate…” | 41 |

### Symbol-tag usage (top)

belonging 10 · movement 9 · restraint 9 · accountability 9 · nurture 7 · pause 7 · choice 6 · release 6 · threshold 6 · clarity 6

Unused / near-unused tags (cleanup candidates): freedom, agency, wisdom, surrender, transformation, alchemy, upheaval, breakthrough, guidance, subconscious, delay (as tag — delay also exists as transform).

---

## Canonical fidelity

**Result:** PASS — no confirmed CLEAR-DRIFT.

Expansion is expected and observed (especially Majors). High-risk cards (`cups_02/05/07/08/10`, `swords_03/05/07/08/09/10`, `pentacles_05/07/10`) preserve anti-prediction hedges present in canon (e.g. swords_10 mental≠body; pentacles_07 unripe crop≠ROI; cups_02 reciprocity≠marriage prophecy).

---

## Cross-card similarity

Exact substantial duplicates across different cards: **none**.

High-similarity candidates reviewed:

| Pair | Field | Score | Verdict |
|---|---|---|---|
| cups_09 ↔ cups_10 | relationshipDynamic | 0.77 | **MAJOR** — too close for adjacent Cups completion cards (RT-M01) |
| cups_03 ↔ cups_10 | decisionDynamic | 0.64 | MINOR — shared “shared table / circle” decision language |
| pentacles_13 ↔ pentacles_14 | relationshipDynamic | 0.57 | INFO — intentional Queen/King adjacency; still distinguishable on core |

---

## Suit separation

**SUIT COLLAPSE: NO**

Wands remain will/fire/motion; Cups emotion/bond/receptivity; Swords thought/judgment/language; Pentacles matter/craft/resource/exchange. Shared *syntax* (template stems) does not erase suit *substance*.

No profile was judged relocatable to another suit with trivial wording change.

---

## Rank analysis

**RANK COLLAPSE: NO**

Cross-suit same-rank core Jaccard peaks remain modest (~0.35–0.42 on a few court pairs). Ace–Ten progressions retain distinct centers within each suit. Soft rank scaffolding is visible but not flattening.

---

## Court cards

**COURT COLLAPSE: NO**

Within-suit Page/Knight/Queen/King differ on core, relationship, decision, and action (covered by Phase 3B tests). Across suits, Pages are not identical “student” stubs; Kings are not identical “CEO” stubs. No systematic gender moralism / wealth hierarchy found in V2 courts.

---

## Reversed transforms

**REVERSED GENERICITY: CONCERNS**

- Transform inventory is used (not a single enum everywhere).  
- **excess** is over-represented (37).  
- **release** nearly unused (1).  
- More serious than enum skew: many profiles **copy shadow into reversed.expression** (see Field-role).

---

## Field-role redundancy

**FIELD-ROLE REDUNDANCY: CONCERNS** (MAJOR cluster)

Observed pattern (especially Cups + many Pentacles): `shadow.en` token-identical or near-identical to `reversed.expression.en`.

Example evidence (`cups_05`):

- shadow: “Gaze may lock only on loss; despair or denial may dominate.”  
- reversed.expression: **identical string**

This collapses two fields that Evidence Engine would treat as distinct orientation signal.

Other fields (desire/fear/tension/decision/action) generally retain separate roles, though desire often uses the shared “There may be a wish…” stem.

---

## Template / genericity analysis

**TEMPLATE MONOTONY: CONCERNS** (MAJOR)

Structural consistency of reflective voice is intentional. Frequency of fixed stems is high enough that an AI synthesizer would inherit **robotic sameness** unless templates are diversified before wiring.

Separate:

- STRUCTURAL CONSISTENCY — retained (good for contract)  
- AUTHORING MONOTONY — excessive stem reuse (needs remediation)

---

## Metaphor analysis

Metaphors remain suit-colored (cups/water; fire/wands; threshold/garden/matter for pentacles). Swords use less literal blade vocabulary than expected (INFO). No deck-wide metaphor that obscures meaning found at BLOCKER level.

---

## Symbol-tag ontology

**CONCERNS** (MINOR/INFO)

- High-frequency tags: belonging, movement, restraint, accountability  
- Several tags barely used — ontology cleanup candidates  
- `delay` exists both as tag and as `ReversedTransformKind` — potential confusion  
Do **not** delete/add in this phase.

---

## Keyword-id normalization candidates

**CONCERNS** (MINOR)

Most `keywordIds` are one-off camelCase strings (hundreds of singletons). Useful for human authoring; weak as shared ontology. Candidate future normalization: shared vocab for recurring concepts (mourning, patience, threshold, reciprocity) without losing card specificity.

---

## Localization alignment

**PASS** with INFO notes

Dominant-language sanity already enforced. Spot-check of Majors, 16 courts, and high-risk cards: TR/EN/RU convey the same claim; hedges preserved across locales. No locale introducing forbidden certainty found. Literary polish is uneven (INFO) but not dangerously divergent.

---

## Safety findings

**SAFETY CROSS-DECK: PASS**

No BLOCKER medical/death/violence/financial-certainty/infidelity/mind-reading assertions found in semantic review + regex scan. High-risk cards retain explicit anti-literal framing.

---

## Action-direction findings

**CONCERNS** (MINOR)

Actions are card-colored more often than not, but verbs cluster around notice / name / protect / pause / do-not. Swap-test: most actions would *not* survive blind swap across distant cards; a minority of “name X; do not Y” stems are interchangeable at surface level.

---

## Relationship-dynamic findings

**CONCERNS** (MAJOR for cups_09/10; otherwise MINOR)

Frequent “in a bond…” opener. Most still attach suit-specific content. cups_09 ↔ cups_10 relationshipDynamic similarity is the clearest relational collapse candidate.

---

## Decision-dynamic findings

**CONCERNS** (MINOR)

“The choice…” + “separate X from Y” stems are common. Content usually card-specific. cups_03 ↔ cups_10 decisionDynamic is a soft near-copy.

---

## Evidence-Engine fitness

**EVIDENCE ENGINE FITNESS: CONCERNS → treat as FAIL for readiness**

| Surface | Fitness |
|---|---|
| Discriminative upright identity | Strong |
| Suit / rank contrast | Strong |
| Relationship potential | Moderate (template + one Cups pair) |
| Reversed / orientation signal | **Weak** (shadow≈reversed) |
| Action signal | Moderate |
| Cross-card contrast | Good upright; thin reversed |

**Conclusion:** Dataset gives useful upright discriminative signal, but reverse orientation and prose-template monotony would cause an Evidence Engine to overfit generic stems and under-signal reversals. **Do not consume until MAJOR remediations.**

---

## Blocking findings

None.

---

## Major findings

### RT-M01 — Cups completion relationship near-copy

| | |
|---|---|
| Severity | **MAJOR** |
| Card(s) | `cups_09`, `cups_10` |
| Field(s) | `relationshipDynamic` |
| Evidence | EN token Jaccard ≈ 0.77 |
| Why it matters | Adjacent emotional-completion cards must remain distinct for spread contrast |
| Recommended direction | Rewrite one/both relationshipDynamics to stress personal enough-ness vs shared table/circle without shared stem |

### RT-M02 — Shadow ≈ reversed.expression cloning

| | |
|---|---|
| Severity | **MAJOR** |
| Card(s) | Widespread; confirmed identical/near-identical on many Cups (e.g. `cups_02`,`cups_04`,`cups_05`,`cups_06`,`cups_09`,`cups_12`,`cups_13`,`cups_14`) and several Pentacles |
| Field(s) | `shadow`, `reversed.expression` |
| Evidence | Exact EN string match on multiple cards (e.g. `cups_05`) |
| Why it matters | Evidence Engine loses upright/reversed discriminative field |
| Recommended direction | Author distinct reversed expressions; keep shadow as risk, reversed as orientation transform narrative |

### RT-M03 — Authoring template monotony

| | |
|---|---|
| Severity | **MAJOR** |
| Card(s) | Deck-wide (syntax), especially desire/shadow/core openings |
| Field(s) | Multiple |
| Evidence | “There may be a wish” ≈78; “may slide into” ≈90; “It speaks of” ≈62 |
| Why it matters | Future AI synthesis inherits robotic sameness; reduces perceived craft |
| Recommended direction | Diversify stems while preserving reflective contract; prioritize desire/shadow/core |

---

## Minor findings

### RT-m01 — cups_03 ↔ cups_10 decisionDynamic similarity (0.64)
### RT-m02 — `excess` transform over-concentration (37)
### RT-m03 — Keyword-id singleton sprawl / weak shared ontology
### RT-m04 — Symbol-tag underuse + delay tag/transform dual meaning
### RT-m05 — ActionDirection verb clustering (name/notice/protect/do-not)
### RT-m06 — Swords metaphor under-use relative to suit identity

---

## Info findings

### RT-i01 — Automated fidelity Jaccard false positives on Majors (document heuristic limit)
### RT-i02 — pentacles_13/14 relationshipDynamic adjacency (acceptable Queen/King tension)
### RT-i03 — `release` transform used once — optional enrichment later
### RT-i04 — Literary unevenness TR/EN/RU (not dangerous)
### RT-i05 — Court role scaffolding visible but not collapsed

---

## Clean areas

- 78/78 completeness + exact deck id equality  
- No exact cross-card long-field duplicates  
- Suit centers intact  
- Rank progression intact  
- Courts distinct within/across suits  
- Safety hedges on high-risk cards  
- Canonical identity preserved (human review)  
- Locale dominant-language + alignment spot-check  

---

## Recommended remediation order

1. **RT-M02** — rewrite reversed.expression where cloned from shadow (Cups first, then Pentacles)  
2. **RT-M01** — separate cups_09 / cups_10 relationshipDynamics  
3. **RT-M03** — diversify highest-frequency stems (desire/shadow/core) without changing meaning  
4. RT-m01 decisionDynamic polish  
5. Keyword-id / symbol-tag ontology cleanup (non-blocking)  
6. Re-run Phase 3C checklist → only then consider Evidence Engine  

**Do not start Narrative Evidence Engine until product-owner clears MAJOR findings.**

---

## Phase 3C.1 follow-up — RT-M02 remediation

| Field | Value |
|---|---|
| Status | **RESOLVED** |
| Phase | 3C.1 |
| Start HEAD | `05c485656fd890fdaf20eaaa4db7de221c390fab` |
| Initial exact shadow↔reversed clones | **19** |
| Initial high-similarity (≥0.75) candidates | **9** |
| Additional soft clones remediitated | **8** |
| Profiles changed | **36** (reversed.expression only) |
| Transform assignments changed | **NONE** |
| Final exact clones | **0** |
| Unresolved semantic near-clones | **0** |
| RT-M01 | **OPEN** (untouched) |
| RT-M03 | **OPEN** (untouched) |
| DECK READY FOR EVIDENCE ENGINE | **NO** (remaining MAJOR findings) |

Historical Phase 3C finding RT-M02 remains documented above as evidence; this section records resolution.

---

## Phase 3C.2 follow-up — RT-M01 remediation

| Field | Value |
|---|---|
| Status | **RESOLVED** |
| Phase | 3C.2 |
| Start HEAD | `b03fac88ed45948d779ea208fd1536d7b39c3223` |
| Fields changed | `cups_09.relationshipDynamic` · `cups_10.relationshipDynamic` (TR/EN/RU) |
| Before similarity (EN Jaccard) | **≈ 0.77** |
| After similarity (EN Jaccard) | **0.107** |
| cups_09 identity | Personal emotional contentment brought into connection without requiring the bond to manufacture worth |
| cups_10 identity | Shared emotional field / circle-culture with room for more than one person |
| Blind-swap cups_09→cups_10 | **NO** — personal contentment-into-connection ≠ shared circle field |
| Blind-swap cups_10→cups_09 | **NO** — multi-person belonging field ≠ individual sufficiency-in-connection |
| Locales | TR/EN/RU aligned; no destiny/mind-reading |
| Safety | PASS |
| RT-M02 | **RESOLVED** (unchanged) |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |

Historical Phase 3C finding RT-M01 remains documented above as evidence; this section records resolution.

---

## Phase 3C.3A follow-up — RT-M03 semantic template remediation, part 1

| Field | Value |
|---|---|
| Status | **PARTIALLY REMEDIATED — STILL OPEN** |
| Phase | 3C.3A |
| Start HEAD | `776f040778ed61a94cead565b60016f5c8dc0e61` |
| Fields in scope | `coreMeaning` · `desire` · `shadow` (TR/EN/RU aligned; EN structural diversification) |
| Fields **not** in scope | `relationshipDynamic` · `decisionDynamic` · `actionDirection` |
| Profiles touched | **78** |
| coreMeaning fields changed | **62** (EN) |
| desire fields changed | **78** (EN) |
| shadow fields changed | **47** (EN) |
| TR/RU | Preserved from pre-3C.3A (already naturally diverse; opener share ≪ 25%) |

### Before metrics (opener stem = first 4 normalized tokens)

| Field · locale | Top opener | Count | % of 78 |
|---|---|---:|---:|
| coreMeaning · EN | `it speaks of a` | 29 | 37.2% |
| desire · EN | `there may be a` | 78 | 100.0% |
| shadow · EN | (opener varied; phrase `may slide into` mid-sentence) | — | — |
| coreMeaning · TR | max stem | 1 | 1.3% |
| desire · TR | max stem | 1 | 1.3% |
| shadow · TR | max stem | 1 | 1.3% |
| coreMeaning · RU | max stem | 1 | 1.3% |
| desire · RU | max stem | 2 | 2.6% |
| shadow · RU | max stem | 2 | 2.6% |

Historical exact EN phrase counts (core+desire+shadow):

| Phrase | Before |
|---|---:|
| `It speaks of` | **62** |
| `There may be a wish` | **78** |
| `may slide into` | **47** |

### After metrics

| Field · locale | Top opener | Count | % of 78 |
|---|---|---:|---:|
| coreMeaning · EN | `the meaning turns on` | 6 | 7.7% |
| desire · EN | `part of this archetype` | 13 | 16.7% |
| shadow · EN | `at the edge of` | 8 | 10.3% |
| coreMeaning · TR | max stem | 1 | 1.3% |
| desire · TR | max stem | 1 | 1.3% |
| shadow · TR | max stem | 1 | 1.3% |
| coreMeaning · RU | max stem | 1 | 1.3% |
| desire · RU | max stem | 2 | 2.6% |
| shadow · RU | max stem | 2 | 2.6% |

Historical exact EN phrase counts after:

| Phrase | After |
|---|---:|
| `It speaks of` | **0** |
| `There may be a wish` | **0** |
| `may slide into` | **0** |

| Check | Result |
|---|---|
| Top opener share ≤ 25% (all target × locales) | **PASS** |
| Replacement monoculture | **NO** |
| Canonical fidelity (changed coreMeaning) | FAITHFUL / FAITHFUL-WITH-EXPANSION; QUESTIONABLE-DRIFT=0; CLEAR-DRIFT=0 |
| Locale alignment TR/EN/RU | **PASS** |
| Safety | **PASS** |
| RT-M01 | **RESOLVED** (untouched) |
| RT-M02 | **RESOLVED** (shadow≠reversed exact clones=0; near-clones=0) |
| RT-M03 | **PARTIALLY REMEDIATED — STILL OPEN** (interaction fields not yet remediated) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |

Historical Phase 3C finding RT-M03 remains documented above as evidence; this section records part-1 remediation only.

---

## Method notes / limitations

- Automated similarity is a **candidate generator**, not proof of defect.  
- Fidelity token overlap vs poetic canon under-calls FAITHFUL majors.  
- This audit did not rewrite production profiles by design (auditor ≠ implementer).  
- Test-only diagnostics live under `test/features/tarot/narrative_domain/red_team/`.
