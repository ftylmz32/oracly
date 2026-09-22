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

## Phase 3C.3A.1 follow-up — RT-M03A naturalness repair

| Field | Value |
|---|---|
| Status | **COMPLETE** (naturalness frozen for core/desire/shadow EN) |
| Phase | 3C.3A.1 |
| Start HEAD | `8e6eedb6cbae693a236c1273725d75fcec63937f` |
| Reason | Independent review: 3C.3A replaced historical stems with a rotation of new scaffolds; some EN fields became fragmentary / telegraphic |
| Scope | `coreMeaning.en` · `desire.en` · `shadow.en` only |
| TR/RU | **NONE changed** (remain aligned) |

### Replacement-scaffold counts (EN, target fields)

| Phrase family | Before (at 3C.3A tip) | After |
|---|---:|---:|
| At the center: | 15 | 0 |
| The meaning turns on | 6 | 0 |
| Part of this archetype | 13 | 0 |
| At the edge of this archetype | 8 | 0 |
| What is wanted is | 6 | 0 |
| The pull is | 6 | 0 |
| A need to | 11 | 0 |
| The energy leans toward | 7 | 0 |
| Without balance | 8 | 0 |
| The risk is | 5 | 0 |

### Change accounting (vs 3C.3A tip)

| | |
|---|---|
| Profiles changed | **77** |
| coreMeaning.en | **44** |
| desire.en | **73** |
| shadow.en | **33** |
| Known stilted / fragmentary / template-swap remaining | **0** |
| Canonical fidelity | QUESTIONABLE-DRIFT=0 · CLEAR-DRIFT=0 |
| Safety | **PASS** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** (exact clones=0; near-clones=0) |
| RT-M03 | **PARTIALLY REMEDIATED / OPEN** (interaction fields still pending 3C.3B) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| 3C.3A naturalness quality | **FROZEN** |

### Phase 2 / 2.1 targeted-count note

Canonical command: `flutter test test/features/tarot/narrative_v2/`

Files (5): `narrative_tarot_corpus_coverage_test.dart`, `narrative_tarot_corpus_schema_test.dart`, `narrative_tarot_hard_failure_contract_test.dart`, `narrative_tarot_phase21_hardening_test.dart`, `narrative_tarot_quality_contract_test.dart`

Result at 3C.3A.1 validation: **27 passed · 0 failed · 0 skipped · 0 timed out**

The Phase 3C.3A final report's **26** was a reporting/scope miscount in the summary table (no Phase 2 files changed in 3C.3A; full Flutter rose exactly +6 for the six new RT-M03A tests). Re-running the canonical target confirms **27**.

---

## Phase 3C.3B follow-up — RT-M03 interaction semantics remediation (part 2)

| Field | Value |
|---|---|
| Status | **REMEDIATED — PENDING FINAL RE-AUDIT** |
| Phase | 3C.3B |
| Start HEAD | `71c2b528c11bd74af51d2aedade45cc99d32093b` |
| Fields in scope | `relationshipDynamic` · `decisionDynamic` · `actionDirection` |
| Fields **not** in scope | `coreMeaning` · `light` · `shadow` · `tension` · `desire` · `fear` · `upright` · `reversed` · `keywordIds` · `symbolTags` |
| Profiles touched | **75 / 78** (majors 01/02/12 already naturally varied; no change needed) |
| relationshipDynamic changed | **53** |
| decisionDynamic changed | **74** |
| actionDirection changed | **52** |
| Locale field changes | TR **179** · EN **179** · RU **179** (each field always edited across all three locales together) |
| By suit (rel/dec/act) | Major **0/19/0** · Wands **13/13/14** · Cups **12/14/11** · Swords **14/14/11** · Pentacles **14/14/14** |

### Before metrics (opener stem = first 4 normalized tokens; measured at Phase 3C.3B start HEAD)

| Field · locale | Top opener | Count | % of 78 |
|---|---|---:|---:|
| relationship · EN | (diverse; every 4-token opener unique) | 1 | 1.3% |
| relationship · TR | (diverse; every 4-token opener unique) | 1 | 1.3% |
| relationship · RU | `в связи может явиться` | 19 | 24.4% |
| decision · EN | `the choice leans on` | 11 | 14.1% |
| decision · TR | `seçim gece kaygısından ayrı` | 3 | 3.8% |
| decision · RU | `выбор проясняет что действительно` | 3 | 3.8% |
| action · EN/TR/RU | (diverse; every 4-token opener unique) | 1 | 1.3% |

The opener-level metric alone understated the problem: `relationshipDynamic` and `actionDirection` varied their first four tokens per card while still embedding an identical **mid-sentence scaffold** ("… may appear **in a bond**; it asks to **separate A from B**" / "[do], [do]; **do not** [Y]"), and `decisionDynamic` was near-universally subject-led by "The choice…" / "The decision…" regardless of the verb that followed.

Historical/discovered phrase-family counts (EN, across relationship+decision+action; TR/RU equivalents found by inspection):

| Phrase family | Before |
|---|---:|
| `in a bond` (EN) | **52** |
| `the choice` (EN, decisionDynamic subject) | **60** |
| `asks to separate` (EN) | **39** |
| `do not` (EN, actionDirection) | **62** |
| `bağda` (TR) | **53** |
| `seçim` (TR, decisionDynamic subject) | **59** |
| `в связи` (RU) | **51** |
| `выбор` (RU, decisionDynamic subject) | **64** |

Action leading-verb (EN) baseline: `name` 12 (15.4%, already below 25%), 45 distinct leading tokens across 78 — RT-m05 was **lexical clustering only**, not a generic/interchangeable-content problem (verified by content: each "name X" instructs a card-specific object).

High-similarity candidates (Jaccard ≥0.5) before remediation: **9** — `cups_09↔cups_10` relationshipDynamic (frozen, already resolved in 3C.2, excluded here), `cups_06↔pentacles_06` 0.538, `cups_13↔pentacles_06` 0.500, `swords_11↔pentacles_11` 0.500, `pentacles_01↔pentacles_02` 0.500, `pentacles_06↔pentacles_10` 0.538, `pentacles_13↔pentacles_14` 0.571 (RT-i02, acceptable Queen/King adjacency), **`cups_03↔cups_10` decisionDynamic 0.643 (RT-m01)**, `swords_03↔swords_06` 0.500, `swords_03↔pentacles_04` 0.500.

Same-card role redundancy: `pentacles_13` relationshipDynamic↔actionDirection = 0.50 (both used the same "separate care from imposing direction" framing).

### Remediation approach

- **relationshipDynamic** (Minors only — Majors already varied): replaced the "`[situation] may appear in a bond; it asks to separate A from B`" scaffold with Major-Arcana-style varied phrasing (direct statement, favoring/warning/reminding constructions, conditional framing), stated between **two people** rather than defaulting to the noun "bond" as filler.
- **decisionDynamic** (deck-wide, Majors + Minors): restructured the grammatical subject away from "The choice / The decision / Karar / Seçim / Выбор [verb]…" for the large majority of cards, moving the operative decision-logic concept (timing, cost, reciprocity, evidence, boundary, trade-off, momentum, responsibility, etc.) into the subject position instead. Semantic content (the specific distinction each card draws) was preserved; only the sentence architecture changed.
- **actionDirection** (Minors mostly, a few Majors already clean): reduced the "`[do], [do]; do not [Y]`" bipartite imperative for a majority of affected cards, replacing with direct action, observational instruction, conditional direction, or small-experiment framing while keeping a natural minority of genuine imperative+caution forms.
- **Self-audit finding mid-remediation**: an early pass replaced "asks to separate A from B" with a new mid-sentence connector family ("*is worth telling/keeping/naming apart from*" EN, "*ayırmakta fayda var / farklı bir şeydir*" TR, "*не то же самое*" RU) that reached ~31% of touched `relationshipDynamic` fields — a replacement monoculture. Caught via self-review before finalizing; **9 relationshipDynamic fields were rewritten a second time** (`cups_06/07/08`, `pentacles_05/09/12`, `swords_08/09/10`) into non-contrastive structures (conditional/observational framing) to bring the family down to **8/54 touched (14.8%)**, with the remainder judged natural (single, content-specific, non-mechanical uses). This is recorded so the pattern is not silently missed in the Phase 3C.4 re-audit.
- `cups_03` / `cups_10` `decisionDynamic` rewritten to the canonical distinction requested: `cups_03` now turns on whether the table's celebration is **reciprocal in the moment** (shared participation vs. one person's solo win); `cups_10` now turns on **durability over time** (whether the shared circle actually holds vs. merely looking harmonious today).
- `pentacles_13` `actionDirection` rewritten to a concrete behavioral instruction ("keep tending / loosen your grip") instead of restating the relationshipDynamic's abstract distinction, resolving the same-card redundancy.
- `cups_09` / `cups_10` `relationshipDynamic` — **untouched** (RT-M01 frozen); only their `decisionDynamic` / `actionDirection` were reviewed and rewritten like the rest of the deck.

### After metrics

| Field · locale | Top opener | Count | % of 78 |
|---|---|---:|---:|
| relationship · EN | `distance between two people` | 2 | 2.6% |
| relationship · TR | (4-way tie, `iki kişi arasında(ki) …`) | 2 | 2.6% |
| relationship · RU | `между двумя людьми может` | 9 | 11.5% |
| decision · EN | `what matters is whether` | 2 | 2.6% |
| decision · TR | (diverse; every 4-token opener unique) | 1 | 1.3% |
| decision · RU | `то что здесь действительно` | 2 | 2.6% |
| action · EN/TR/RU | (diverse; every 4-token opener unique) | 1 | 1.3% |

Historical phrase counts after:

| Phrase family | After |
|---|---:|
| `in a bond` (EN) | **2** (major_19, swords_10 — single natural uses, not a scaffold) |
| `the choice` (EN, decisionDynamic subject) | **0** |
| `asks to separate` (EN) | **0** |
| `do not` (EN, actionDirection) | **5** |
| `bağda` (TR) | **3** |
| `seçim` (TR, decisionDynamic subject) | **1** |
| `в связи` (RU) | **3** |
| `выбор` (RU, decisionDynamic subject) | **3** |
| `отделить` (RU, generic verb, no longer a fixed template) | **13** |

Action leading-verb (EN) after: `name` 12 (15.4%, unchanged share, still well under 25%), **41** distinct leading tokens — confirms RT-m05 was lexical, not semantic, clustering; verdict unchanged: **non-semantic / acceptable**.

High-similarity candidates (Jaccard ≥0.5) after remediation: **0** (full 78×78 pairwise scan across relationshipDynamic and decisionDynamic, EN).

Same-card role redundancy (relationshipDynamic vs decisionDynamic vs actionDirection, Jaccard ≥0.5): **0** cards flagged (`pentacles_13` resolved).

### `cups_03` ↔ `cups_10` decisionDynamic (RT-m01)

| | |
|---|---|
| Before similarity (EN Jaccard) | **0.643** |
| After similarity (EN Jaccard) | **0.161** |
| `cups_03` identity | Decision turns on whether the table's celebration is genuinely reciprocal right now (shared participation vs. one person's solo win) |
| `cups_10` identity | Decision turns on whether the shared circle actually endures over time (durability vs. surface harmony) |
| Blind-swap `cups_03`→`cups_10` | **NO** — momentary reciprocity ≠ long-term durability |
| Blind-swap `cups_10`→`cups_03` | **NO** — long-term durability ≠ momentary reciprocity |
| Status | **RESOLVED** |

### RT-m05 action-verb clustering

| | |
|---|---|
| Before | `name` 12/78 (15.4%), 45 distinct leads |
| After | `name` 12/78 (15.4%), 41 distinct leads |
| Verdict | **Lexical clustering only, non-semantic** — each "name X" instructs a distinct, card-specific object; no cross-card interchangeability found on spot-check. No remediation required beyond the natural variation already introduced by other actionDirection rewrites. |

### Gate results

| Check | Result |
|---|---|
| Interaction top opener share ≤25% (all target × locale) | **PASS** |
| Replacement monoculture | **NO** (self-caught mid-pass "worth telling apart" / "не то же самое" family; corrected — see remediation approach) |
| Naturalness | **PASS** (manual read of all 75 changed cards; reflective register preserved, no database prose, no fragments) |
| Canonical fidelity | **PASS** — semantic content of each distinction preserved from the pre-3C.3B text; no new relational/decision/action claim invented for prose variety |
| Field-role distinctness (relationship vs decision vs action, same card) | **PASS** (0 flagged ≥0.5; `pentacles_13` fixed) |
| Full-string exact duplicates (relationship/decision/action × TR/EN/RU) | **0** |
| Safety (destiny/mind-reading/financial/medical/violence) | **PASS** |
| RT-M01 (`cups_09`/`cups_10` relationshipDynamic) | **RESOLVED**, untouched, regression-tested |
| RT-M02 (shadow↔reversed) | **RESOLVED**, untouched, regression-tested (exact clones 0; near-clones 0) |
| 3C.3A / 3C.3A.1 naturalness (`coreMeaning`/`desire`/`shadow`) | **FROZEN**, untouched, regression-tested |
| RT-m01 (`cups_03`/`cups_10` decisionDynamic) | **RESOLVED** |
| RT-m05 (action verb clustering) | **RESOLVED as lexical-only / non-semantic** |
| RT-M03 | **REMEDIATED — PENDING FINAL 78-CARD RE-AUDIT** |
| DECK READY FOR EVIDENCE ENGINE | **NO** — Phase 3C.4 independent re-audit required before this can change |

Historical Phase 3C finding RT-M03 remains documented above as evidence; this section records the interaction-field (part 2) remediation only. Phase 3C.3A/3C.3A.1 already remediated `coreMeaning`/`desire`/`shadow` and remain untouched here.

---

## Method notes / limitations

- Automated similarity is a **candidate generator**, not proof of defect.  
- Fidelity token overlap vs poetic canon under-calls FAITHFUL majors.  
- This audit did not rewrite production profiles by design (auditor ≠ implementer).  
- Test-only diagnostics live under `test/features/tarot/narrative_domain/red_team/`.
