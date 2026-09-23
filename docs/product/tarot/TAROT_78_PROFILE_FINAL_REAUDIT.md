# TAROT 78-PROFILE FINAL RE-AUDIT (Phase 3C.4)

**Auditor mode — production profiles READ-ONLY**  
**Branch:** `fix/final-product-remediation-20260922`  
**Audit HEAD:** `b7180fc6498456c3badc063dff207497aef47087`  
**Date:** 2026-09-23  
**Profiles reviewed:** **78 / 78**

Historical Phase 3C findings remain in `TAROT_78_PROFILE_RED_TEAM.md`.  
This document is an independent CURRENT-HEAD re-evaluation.

---

## Executive verdict

| Gate | Result |
|---|---|
| Phase 3C.4 audit completeness | **PASS** (audit finished) |
| **DECK READY FOR EVIDENCE ENGINE** | **NO** |

### Why readiness is NO

1. **BLOCKER** — `major_01.desire.en` is cross-card contaminated (“Honest leave-taking…”) while TR/RU retain Magician effort/mark semantics.  
2. **MAJOR** — human-judged shadow≈reversed paraphrase collapse on multiple courts/pages (automated Jaccard ≥0.75 gate still green; semantic near-clones unresolved).  
3. **MAJOR** — keyword-id ontology is singleton-heavy (**352 / 397** unique ids appear once) and is not fit as a deterministic Evidence Engine grouping selector.  
4. **MAJOR** — residual unnatural EN compounds (`circle-culture`, Swords 9 hyphen stacks) would amplify non-human phrasing if consumed as evidence text.

RT-M01 remains **RESOLVED**.  
RT-M02 returns to **OPEN** (exact clones = 0; unresolved human semantic near-clones > 0).  
RT-M03 returns to **OPEN** (prior remediation incomplete given contamination + residual scaffolds).

---

## A — Structural integrity

| Check | Result |
|---|---|
| Catalog count | **78** |
| Unique canonical ids | **78** |
| Missing / extra / duplicate | **0 / 0 / 0** |
| Major / Minors | **22 / 56** |
| Suit counts | Cups 14 · Wands 14 · Swords 14 · Pentacles 14 · Major 22 |
| Locales TR/EN/RU on required semantic fields | **Present** (domain `isComplete` gates green) |
| Orientation contract | Present (expression + transforms + keywordIds) |
| symbolTags | Non-empty; ontology-bound (existing tests) |
| profileRevision | ≥ 1 across deck |
| Fabricating lookup | `NarrativeTarotProfileCatalog.lookup` returns null for unknown ids |

**Structural: PASS**

---

## B — Canonical fidelity

Human review of all 78 against ORACLY/RWS identity (core + interaction + orientation surfaces).

| Class | Count |
|---|---:|
| FAITHFUL | **70** |
| FAITHFUL-WITH-EXPANSION | **7** |
| QUESTIONABLE-DRIFT | **0** |
| CLEAR-DRIFT | **1** |

### CLEAR-DRIFT

| Card | Field | Locale | Evidence |
|---|---|---|---|
| `major_01` | `desire` | EN | `Honest leave-taking may be sought — to see one's own effort leave a real mark on the outcome.` |

TR/RU correctly express Magician desire (effort leaving a real mark). EN prefix imports Cups-8 leave-taking semantics. This is locale corruption / paste contamination, not Magician meaning.

**Fidelity gate for readiness: FAIL** (CLEAR-DRIFT ≠ 0)

---

## C — Naturalness

| Locale | Verdict |
|---|---|
| EN | **CONCERNS** — generally readable after 3C.3A.1 / 3C.3B; residual compounds + one contaminated desire |
| TR | **PASS** — natural; no mass robotic “Bu kart … anlatır” monoculture |
| RU | **CONCERNS** — natural overall; residual contrast scaffold `не то же самое` (~13 relationship hits) still functions as a soft template |

Deep-reviewed: all Majors, all 16 courts, high-risk Cups/Swords/Pentacles listed in the prompt.

Known-risk phrase inspection:

| Phrase | Assessment |
|---|---|
| `circle-culture` (`cups_10.relationshipDynamic.en`) | **Unnatural** — MAJOR craft defect |
| `mind-load` / `catastrophe-dream` / `insomnia-identity` / `guilt-load` (`swords_09`) | **Unnatural hyphen stack** — MAJOR |
| `full cup` / `full table` | Acceptable metaphor when in complete sentences |
| `care starts to feel like control` | Natural enough (INFO only if repeated) |
| `sheath-rest` | Not observed as a widespread defect in this pass |

---

## D — Replacement monoculture recheck

| Family | Approx. deck hits (target semantic fields) | Judgment |
|---|---:|---|
| EN `worth telling/keeping/naming apart` | **3** | Individually mostly natural; not monoculture |
| EN `not the same as` / “stays different from…” | **~6+** court/interaction frames | Soft template rhyme — **INFO / craft** |
| EN `Quietly, one may seek` | **8** | Mild desire opener cluster (10.3% opener share) — **INFO**, under 25% gate |
| TR `aynı şey değildir` / `ayırmakta fayda` | **~6** | Soft contrast scaffold — **INFO** |
| RU `не то же самое` | **13** | Still a recognizable 3C.3B residual template — **MINOR** (not alone blocking if content card-specific) |
| Historical 3C.3A scaffolds (`At the center`, `Part of this archetype`, `At the edge…`) | **0** | Cleared |

**Replacement monoculture (hard):** NO  
**Hidden soft templates:** YES (RU contrast frame; Quietly desire opener) — non-blocking alone, escalate with other MAJORs.

---

## E — Cross-card distinctness

Automated EN Jaccard ≥ 0.55 across core/shadow/desire/relationship/decision/action/orientations: **0 pairs**.

Human review still finds:

- Court shadow↔reversed **same triad rephrased** (not high Jaccard, but same meaning facets)
- Soft structural rhyme in court relationship contrast frames

No Ace–Ten rank collapse or suit identity collapse observed.

---

## F — Suit / rank / court identity

| Check | Result |
|---|---|
| Suit collapse | **NO** |
| Rank collapse | **NO** |
| Court collapse | **NO** (roles distinct; hierarchy not infant→king) |

---

## G — Field-role separation

| Pair | Verdict |
|---|---|
| core vs upright | Generally distinct |
| desire vs action | Generally distinct |
| decision vs action | Generally distinct |
| relationship vs action | Generally distinct |
| **shadow vs reversed** | **FAIL on multiple courts/pages** (semantic paraphrase) |

**Field-role collapse:** YES (shadow/reversed facet — localized, not deck-wide exact clones)

---

## H — RT-M01 re-audit

| | |
|---|---|
| cups_09 relationship | Personal emotional sufficiency / contentment brought into connection |
| cups_10 relationship | Shared multi-person belonging / circle field |
| EN Jaccard | **0.107** |
| Blind swap | **NO / NO** |
| Destiny / mind-reading | Absent |

**RT-M01: RESOLVED**

---

## I — RT-M02 re-audit

| Check | Result |
|---|---|
| Exact EN shadow↔reversed clones | **0** |
| Automated Jaccard ≥ 0.75 candidates | **0** |
| Automated Jaccard ≥ 0.55 soft list | cups_11 (0.57), swords_14 (0.64) |
| Human unresolved semantic near-clones | **Several courts/pages** (cups_11, swords_11, swords_13, swords_14, wands_11; milder cups_10 / pentacles_10) |

**RT-M02: OPEN** — exact-clone gate remains green; **semantic near-clone unresolved ≠ 0** under human judgment.

TR/RU spot-check: same facet echo pattern often mirrors EN (not EN-only).

---

## J — RT-M03 re-audit

Surfaces: coreMeaning · desire · shadow · relationshipDynamic · decisionDynamic · actionDirection

| Check | Result |
|---|---|
| Opener ≤25% gates (existing RT-M03A/B tests) | Green |
| Historical stems reduced | Yes |
| Naturalness frozen claim | Broken by `major_01` EN contamination + residual compounds |
| Soft residual templates | Quietly… / RU не то же самое |

**RT-M03: OPEN**

---

## K — Cups 03 / Cups 10 decision

| | |
|---|---|
| cups_03 | Present reciprocity / shared participation now |
| cups_10 | Durability of shared emotional system over time |
| EN Jaccard | **0.161** |
| Blind swap | **NO / NO** |
| Status | **RESOLVED** (prior RT-m01) |

---

## L — Action quality

Top first verbs (EN): `name` 12 · `see` 6 · `notice` 5 · `let` 5 · …

| Check | Result |
|---|---|
| Card-specific content under verbs | Generally yes after 3C.3B |
| Swap-onto-unrelated-cards | Mostly no |
| Fortune / commanding advice | Not systemic |
| RT-m05 | **NON-BLOCKING** (lexical clustering only) |

---

## M — Localization alignment

| Verdict | **CONCERNS** |
|---|---|
| Material divergence | **`major_01.desire` EN ≠ TR/RU** (BLOCKER) |
| Deep-review Majors/courts/high-risk | Otherwise aligned; hedges preserved on Death / Swords 9–10 / Cups 2–3 |
| RU soft intensifier | Occasional sharper wording (INFO), not certainty claims |

---

## N — Safety final

| Area | Result |
|---|---|
| Destiny / soulmate / future certainty | No systemic authored claims |
| Death prediction | `major_13` / `swords_10` retain mental/transform hedges |
| Diagnosis | `swords_09` explicitly anti-diagnosis |
| Self-harm / violence instruction | Not observed |
| Financial advice | Pentacles safety tests green; prose observational |
| Mind-reading / infidelity accusation | Not observed as authored certainty |

**SAFETY: PASS** (no BLOCKER safety issue).  
Note: contamination on Magician desire is a **fidelity** defect, not a safety claim.

---

## O — Original minor findings (current classification)

| ID | Topic | Current |
|---|---|---|
| RT-m01 | cups_03↔cups_10 decision | **RESOLVED** |
| RT-m02 | `excess` transform concentration (37) | **NON-BLOCKING** — common reversed mode; distribution uneven but semantically plausible |
| RT-m03 | keyword-id singleton sprawl | **BLOCKING** for Evidence Engine keyword grouping (352/397 singletons) |
| RT-m04 | symbol-tag underuse / delay dual sense | **NON-BLOCKING** with **CONCERNS** — tags usable as sparse relation hints, not primary selectors |
| RT-m05 | action verb clustering | **NON-BLOCKING** |
| RT-m06 | Swords metaphor under-use | **NON-BLOCKING** (INFO craft) |

---

## P — Keyword / symbol ontology for Evidence Engine

Contract intent: profiles (including `keywordIds` / `symbolTags`) feed deterministic `NarrativeEvidenceBuilder` as profile slice facts.

| Signal | Stats | Engine readiness |
|---|---|---|
| keywordIds | **397** unique · **352** singletons (~88.7%) | **BLOCKING** as deterministic recurrence/grouping keys |
| symbolTags | Coarse shared tags (belonging 10, movement 9, …) | **CONCERNS** — OK as sparse motifs; weak as primary identity |

**Recommendation (do not implement here):** ontology remediation pass before Evidence Engine planning — merge near-synonym keyword ids; define a small closed shared lexicon; keep symbolTags sparse and curated.

---

## Q — Reversed transform distribution

| Transform | Count |
|---|---:|
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

**Verdict:** Uneven but mostly semantically justified. `release` near-unused is INFO. **Not** an Evidence Engine blocker if transforms remain soft orientation hints rather than exclusive selectors.

---

## R — Evidence Engine fitness

| Dimension | Verdict |
|---|---|
| Card identity discrimination | Strong for most cards; **broken for Magician desire EN** |
| Upright/reversed discrimination | Weakened on several courts (shadow≈reversed paraphrase) |
| Relationship / decision / action signals | Generally usable after 3C.3B |
| Suit/rank contrast | Pass |
| Localization stability | Fail on Magician desire |
| keywordIds usefulness | Fail as deterministic grouper |
| symbolTags usefulness | Soft pass with concerns |
| Safety stability | Pass |
| Canonical fidelity | Fail (1 CLEAR-DRIFT) |

**EVIDENCE ENGINE FITNESS: FAIL**

---

## S — Findings register

### BLOCKER

| ID | Cards | Fields | Locale | Evidence | Why it matters | Engine impact | Direction |
|---|---|---|---|---|---|---|---|
| **FR-B01** | `major_01` | `desire` | EN | “Honest leave-taking may be sought — …” while TR/RU are effort/mark | Wrong-card semantics in EN | Magician evidence would retrieve leave-taking | Rewrite EN desire from TR/RU Magician meaning; add locale-alignment guard |

### MAJOR

| ID | Cards | Fields | Locale | Evidence | Why / engine impact | Direction |
|---|---|---|---|---|---|---|
| **FR-M01** | `swords_09` (+ nearby) | light / upright / reversed | EN | mind-load, catastrophe-dream, insomnia-identity, guilt-load | Non-human compounds enter evidence text | Naturalize compounds without meaning change |
| **FR-M02** | `cups_10` | relationshipDynamic | EN | “circle-culture” | Artificial EN vs fine TR/RU | Replace with natural shared-circle phrasing |
| **FR-M03** | `cups_11`, `swords_11`, `swords_13`, `swords_14`, `wands_11` (+ milder `cups_10`, `pentacles_10`) | shadow ↔ reversed.expression | EN (+ mirrored locales) | Same risk triad rephrased | Orientation signal collapses | Distinct reversed orientation narratives; keep shadow as risk |
| **FR-M04** | Deck-wide | upright/reversed.keywordIds | — | 352/397 singletons | Cannot safely group/recurrence on keyword ids | Ontology remediation before Evidence Engine |

### MINOR

| ID | Topic | Direction |
|---|---|---|
| **FR-m01** | RU `не то же самое` residual contrast scaffold (~13) | Diversify only where still template-like |
| **FR-m02** | EN “Quietly, one may seek” desire opener (8) | Optional naturalize; not metric-critical |
| **FR-m03** | `cups_09` “enough” nouning telegraphic | Soft polish |
| **FR-m04** | `swords_10` disaster-identity / mind-cycle compounds | Soft polish (safety hedges keep) |

### INFO

| ID | Topic |
|---|---|
| **FR-i01** | Court relationship “worth telling apart / not the same as” structural rhyme |
| **FR-i02** | `release` transform used once |
| **FR-i03** | RT-m06 Swords metaphor craft unevenness |
| **FR-i04** | Jaccard false-negative limit (human near-clones above automated threshold) |

---

## Counts

| Severity | Count |
|---|---:|
| BLOCKER | **1** |
| MAJOR | **4** |
| MINOR | **4** |
| INFO | **4** |

---

## Status board

| Item | Status |
|---|---|
| RT-M01 | **RESOLVED** |
| RT-M02 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime Narrative V2 | **NOT USER-REACHABLE** |
| Visual System | **NOT IMPLEMENTED** |

---

## Recommended remediation order (for a later implementer prompt)

1. Fix **FR-B01** Magician EN desire (+ locale alignment regression test).  
2. Resolve **FR-M03** court shadow≠reversed semantic near-clones.  
3. Naturalize **FR-M01** / **FR-M02** compounds.  
4. Plan **FR-M04** keyword ontology remediation before Evidence Engine design.  
5. Optional polish minors/info.

**Do not start Narrative Evidence Engine until BLOCKER=0, MAJOR=0, RT-M02/M03 re-closed, and keyword strategy decided.**

---

## Method notes

- Automated opener/similarity gates are necessary but insufficient (Jaccard misses paraphrase collapse; metrics miss Magician contamination).  
- Auditor did not modify `lib/` profiles.  
- Diagnostics helpers under `tool/qa/phase3c4_*.py` are local worktree aids only (not committed as production).

---

## Phase 3C.5A remediation follow-up — FR-B01

| Field | Value |
|---|---|
| Phase | **3C.5A** |
| Finding | **FR-B01** |
| Status | **RESOLVED** |
| Production field | `major_01.desire.en` only |
| TR / RU | **Untouched** |
| Old contaminated EN | `Honest leave-taking may be sought — to see one's own effort leave a real mark on the outcome.` |
| New semantic direction | Magician desire to see own effort / skill / agency leave a real mark on the outcome (aligned with TR/RU; no leave-taking / departure family) |
| New EN | `One may want to see one's own effort leave a real mark on the outcome.` |
| Canonical fidelity (`major_01`) | **FAITHFUL** |
| QUESTIONABLE-DRIFT | **0** |
| CLEAR-DRIFT (from FR-B01) | **0** after remediation |
| Regression test | `test/features/tarot/narrative_domain/narrative_major_01_desire_fr_b01_test.dart` |
| FR-M01 / FR-M02 / FR-M03 / FR-M04 | **Still OPEN** |
| RT-M02 / RT-M03 | **Still OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |

Historical 3C.4 findings above are preserved; this section records remediation only.

---

## Phase 3C.5B remediation follow-up — FR-M03

| Field | Value |
|---|---|
| Phase | **3C.5B** |
| Finding | **FR-M03** |
| Status | **RESOLVED** |
| RT-M02 | **RESOLVED** (exact clones 0; FR-M03 human near-clones in audited scope 0) |

### Initial court/page inventory (shadow vs reversed.expression)

| Card | Classification | Notes |
|---|---|---|
| wands_11 | **SEMANTIC-NEAR-CLONE** | Same triad (scattered zeal / boast / not listening) |
| wands_12 | DISTINCT | Escape vs seeking battle — third facet differs |
| wands_13 | MILD-ECHO | Control/envy shared; possession vs dimming differs |
| wands_14 | MILD-ECHO | Same pressure/ego/listen facets with thin “become” wrap; not escalated in FR-M03 register |
| cups_11 | **SEMANTIC-NEAR-CLONE** | Over-sensitivity / escape-dream / overreading signs |
| cups_12 | DISTINCT | Misdirect + excess mechanism clear |
| cups_13 | DISTINCT | Excess rescue vs deficiency of boundary |
| cups_14 | DISTINCT | Block expression / internalize until freeze |
| swords_11 | **SEMANTIC-NEAR-CLONE** | Gossip / hasty verdict / not listening |
| swords_12 | MILD-ECHO | Transform wrap over shared facets; mechanism present |
| swords_13 | **SEMANTIC-NEAR-CLONE** | Cold verdict / distance-weapon / bitter tongue |
| swords_14 | **SEMANTIC-NEAR-CLONE** | Rigidity / heartless rule / distance idol |
| pentacles_11 | DISTINCT | Misdirect sell/imitate vs avoid by postponing |
| pentacles_12 | DISTINCT | Excess rigidity vs block turning aside |
| pentacles_13 | DISTINCT | Excess smother vs distort stewardship |
| pentacles_14 | MILD-ECHO | Transform wrap; load-misdirect present |
| cups_10 | DISTINCT | Belonging→distort/swell mechanism; leave untouched |
| pentacles_10 | DISTINCT | Lineage→excess/block mechanism; leave untouched |

### Production remediation

| Field | Value |
|---|---|
| Profiles changed | **5** — `cups_11`, `swords_11`, `swords_13`, `swords_14`, `wands_11` |
| Field changed | `reversed.expression` TR/EN/RU only |
| Shadow changed | **NO** |
| Transform assignments changed | **NONE** |
| cups_10 / pentacles_10 edited | **NO** (sufficiently distinct) |

### Blind-swap (human)

| Card | Shadow→reversed swap loss? | Cross-court noun-swap? |
|---|---|---|
| cups_11 | **NO** | **NO** |
| swords_11 | **NO** | **NO** |
| swords_13 | **NO** | **NO** |
| swords_14 | **NO** | **NO** |
| wands_11 | **NO** | **NO** |

### Status after 3C.5B

| Item | Status |
|---|---|
| FR-B01 | **RESOLVED** |
| FR-M03 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| FR-M01 | **OPEN** |
| FR-M02 | **OPEN** |
| FR-M04 | **OPEN** |
| RT-M03 | **OPEN** |
| Locale alignment | **PASS** |
| Safety | **PASS** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Regression test | `narrative_fr_m03_shadow_reversed_separation_test.dart` |

Historical 3C.4 findings above are preserved; this section records remediation only.

---

## Phase 3C.5C remediation follow-up — FR-M01 / FR-M02

| Field | Value |
|---|---|
| Phase | **3C.5C** |
| Findings | **FR-M01**, **FR-M02** |
| Status | **RESOLVED** / **RESOLVED** |
| RT-M03 | **RESOLVED — NON-BLOCKING MINORS REMAIN** |

### Initial EN field audit

**swords_09**

| Field | Classification | Action |
|---|---|---|
| coreMeaning.en | NATURAL | leave |
| light.en | COMPOUND-SHORTHAND (`mind-load`) | rewrite |
| shadow.en | NATURAL | leave |
| tension.en | NATURAL | leave |
| desire.en | COMPOUND-SHORTHAND (`night-mind`) | rewrite |
| fear.en | NATURAL | leave |
| relationshipDynamic.en | NATURAL | leave |
| decisionDynamic.en | NATURAL | leave |
| actionDirection.en | NATURAL | leave |
| upright.expression.en | COMPOUND-SHORTHAND (`night-load`) | rewrite |
| reversed.expression.en | COMPOUND-SHORTHAND (`catastrophe-dream` / `insomnia-identity` / `guilt-load`) | rewrite |

**cups_10**

| Field | Classification | Action |
|---|---|---|
| coreMeaning.en | AWKWARD (`field of shared circle`) | rewrite |
| light.en | NATURAL | leave |
| shadow.en | NATURAL | leave |
| tension.en | NATURAL (defensible) | leave |
| desire.en | AWKWARD (`live a calm shared table`) | rewrite |
| fear.en | NATURAL | leave |
| relationshipDynamic.en | COMPOUND-SHORTHAND (`circle-culture`) | rewrite |
| decisionDynamic.en | NATURAL | leave |
| actionDirection.en | NATURAL | leave |
| upright.expression.en | NATURAL | leave |
| reversed.expression.en | NATURAL | leave |

### Production changes (EN only)

| Card | Fields changed |
|---|---|
| `swords_09` | `light.en`, `desire.en`, `upright.expression.en`, `reversed.expression.en` |
| `cups_10` | `coreMeaning.en`, `desire.en`, `relationshipDynamic.en` |

| Item | Value |
|---|---|
| TR / RU | **Unchanged** |
| keywordIds | **Unchanged** (FR-M04) |
| transforms | **Unchanged** (`swords_09`: excess + internalization) |
| Canonical fidelity | **FAITHFUL** |
| Naturalness read-back | No metadata-leak compounds; ordinary English |
| cups_09 vs cups_10 | Distinction preserved (personal contentment vs shared multi-person circle) |

### Status after 3C.5C

| Item | Status |
|---|---|
| FR-B01 | **RESOLVED** |
| FR-M01 | **RESOLVED** |
| FR-M02 | **RESOLVED** |
| FR-M03 | **RESOLVED** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **RESOLVED — NON-BLOCKING MINORS REMAIN** |
| Remaining MINORS | FR-m01 RU contrast scaffold · FR-m02 “Quietly, one may seek” · FR-m03 cups_09 “enough” nouning · FR-m04 swords_10 compound craft |
| FR-M04 | **OPEN** (blocking for Evidence Engine) |
| DECK READY FOR EVIDENCE ENGINE | **NO** — FR-M04 blocks |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Regression test | `narrative_fr_m01_m02_en_naturalness_test.dart` |

Historical 3C.4 / 3C.5A / 3C.5B findings above are preserved; this section records remediation only.

---

## Phase 3C.5D design follow-up — FR-M04 keyword ontology

| Field | Value |
|---|---|
| Phase | **3C.5D** |
| Finding | **FR-M04** |
| Kind | **DESIGN / MAPPING ONLY** — no production keywordIds changed |
| Plan | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md` |
| Current unique / singleton | **397** / **352** (**88.66%**) |
| Proposed lexicon size | **124** defined · **118** used in projection |
| Projected singleton % | **24.58%** |
| Full 78×orientation mapping | **COMPLETE** |
| Migration table | **COMPLETE** (397 rows) |
| Ambiguous hard-stop | `envy` (+ review notes: pressure SPLIT, balance→stability, delay dual-layer, top-frequency weighting) |
| FR-M04 | **OPEN** — implementation pending ChatGPT review |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Production source modified | **NO** |

Historical findings above are preserved; this section records design only.

---

## Phase 3C.5D.1 — ontology plan semantic mapping repair

| Field | Value |
|---|---|
| Phase | **3C.5D.1** |
| Kind | DESIGN / MAPPING repair only — **no production keywordIds** |
| Plan | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md` (ACTIVE = 3C.5D.1) |
| Confirmed defects repaired | speed→haste · twoWeights/practicalBalance inversion · balance≠stability · instability≠stability · envy≠attachment · fastMind→haste · hastyUnion/diminishedJoy/overcare collapses |
| Semantic inversions after | **0** |
| Semantic loss after | **0** |
| Orientation collapse after | **0** |
| Ambiguous mappings after | **0** |
| Defined / used vocab | **128** / **122** |
| Projected singleton % | **24.59%** |
| FR-M04 | **OPEN** — implementation pending |
| Ontology plan approved for implementation | **YES** pending ChatGPT confirmation of 3C.5D.1 |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Production source modified | **NO** |

---

## Phase 3C.5E — FR-M04 canonical keyword ontology implementation

| Field | Value |
|---|---|
| Phase | **3C.5E** |
| Authority | Phase **3C.5D.1** Appendix B |
| Mapping implemented | **YES** — 78 profiles / 156 orientations |
| Semantic inversion checks | **GREEN** (locked polarity regressions) |
| FR-M04 | **REMEDIATED — PENDING 3C.5F** |
| Deck readiness | **NO** — pending independent 3C.5F re-audit |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Prose / transforms / symbolTags | **UNCHANGED** |

---

## Phase 3C.5F — final keyword ontology + deck readiness audit

| Field | Value |
|---|---|
| Audit | docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_FINAL_AUDIT.md |
| Phase audit | **PASS** |
| FR-M04 | **RESOLVED** |
| BLOCKER / MAJOR | **0 / 0** |
| DECK READY FOR EVIDENCE ENGINE | **YES** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Production modified | **NO** |

