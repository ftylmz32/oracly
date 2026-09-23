# CURRENT HANDOFF

**Living state — factual only**
**Updated:** 2026-09-23 — Tarot Phase 3D.1C.1 Selector Admission + Bounds + Court-Guard Hardening

---

## How to read SHAs in this document

Do **not** treat this file as a live pointer to the branch tip.

| Concept | Value | Meaning |
|---|---|---|
| Canonical branch | `fix/final-product-remediation-20260922` | Active remediation branch |
| Active worktree | `D:/oracly_final_r1` | Where remediation docs/code land |
| Last verified **application/code** baseline (pre-3A) | `173d75228248baf32ea0d4f04fe936665efff342` | R2.1 — prior Flutter-verified code tip (3627/0/15/0) |
| Phase 3A end | `200a3a874fcce763cfdeb2299cfd7177dcb03290` | Major Narrative foundation |
| Phase 3B1 end | `66e814ebac1e84ea6ee556030d8f7af93be7daed` | Wands complete (docs tip) |
| Phase 3B2 end | `c30c3005c11f1e4e52c8612cf9a65828d72a9388` | Cups complete |
| Phase 3B3 task start | `c30c3005c11f1e4e52c8612cf9a65828d72a9388` | Swords start |
| Phase 3B3 end | `427b76bbebdc9a7f161869b9ac66e7c151fa5c95` | Swords profiles commit |
| Phase 3B3.1 end | `2c5c6aa637ed5b5d9407f8e913d18fea543cd839` | Handoff project-memory restoration |
| Phase 3B4 task start | `2c5c6aa637ed5b5d9407f8e913d18fea543cd839` | Pentacles start |
| Phase 3B4 end (profiles) | `c2b5a6d8fa54fe17ba8c000b536d5e3f5a689f01` | 78/78 semantic catalog |
| Phase 3C task start | `c2b5a6d8fa54fe17ba8c000b536d5e3f5a689f01` | Cross-deck red-team |
| Phase 3C end (audit) | `05c485656fd890fdaf20eaaa4db7de221c390fab` | RT-M02/M01/M03 documented |
| Phase 3C.1 task start | `05c485656fd890fdaf20eaaa4db7de221c390fab` | RT-M02 remediation |
| Phase 3C.1 end | `b03fac88ed45948d779ea208fd1536d7b39c3223` | RT-M02 resolved |
| Phase 3C.2 task start | `b03fac88ed45948d779ea208fd1536d7b39c3223` | RT-M01 Cups 09/10 |
| Phase 3C.2 end | `776f040778ed61a94cead565b60016f5c8dc0e61` | RT-M01 resolved |
| Phase 3C.3A task start | `776f040778ed61a94cead565b60016f5c8dc0e61` | RT-M03 part 1 (core/desire/shadow) |
| Phase 3C.3A end | `8e6eedb6cbae693a236c1273725d75fcec63937f` | RT-M03 part 1 diversity gates |
| Phase 3C.3A.1 task start | `8e6eedb6cbae693a236c1273725d75fcec63937f` | RT-M03A naturalness repair |
| Phase 3C.3B task start | `71c2b528c11bd74af51d2aedade45cc99d32093b` | RT-M03 interaction semantics (part 2) |
| Phase 3C.3B end | `b7180fc6498456c3badc063dff207497aef47087` | RT-M03 remediated pending 3C.4 |
| Phase 3C.4 task start | `b7180fc6498456c3badc063dff207497aef47087` | Final 78-card independent re-audit |
| Phase 3C.4 end | `582a2fd88c386bb64746b549950a22fd6ab04557` | Final re-audit docs tip |
| Phase 3C.5A task start | `582a2fd88c386bb64746b549950a22fd6ab04557` | FR-B01 Magician desire EN |
| Phase 3C.5A end | `05aa15cca2d1b6fd00ce0d773f3656cb8ee5dbb4` | FR-B01 Magician desire RESOLVED |
| Phase 3C.5B task start | `05aa15cca2d1b6fd00ce0d773f3656cb8ee5dbb4` | FR-M03 shadow vs reversed |
| Phase 3C.5B end | `4b1c7aecc8b9a77a0452a4a318ccb509b00d4c75` | FR-M03 + RT-M02 RESOLVED |
| Phase 3C.5C task start | `4b1c7aecc8b9a77a0452a4a318ccb509b00d4c75` | FR-M01 / FR-M02 EN naturalness |
| Phase 3C.5C end | `bc9ff060801d941c16ed32b32d8708177fa20c21` | FR-M01/M02 RESOLVED; FR-M04 still OPEN |
| Phase 3C.5D task start | `bc9ff060801d941c16ed32b32d8708177fa20c21` | FR-M04 keyword ontology design |
| Phase 3C.5D end | `9b7086cc92709abe3d3aea11f1f6ee3b6ab34b8b` | Ontology design complete; FR-M04 OPEN |
| Phase 3C.5D.1 task start | `9b7086cc92709abe3d3aea11f1f6ee3b6ab34b8b` | FR-M04 semantic mapping repair |
| Phase 3C.5D.1 end | `a0dbee280b0931469780ad5fbf567343397a80b5` | Ontology plan semantic repair |
| Phase 3C.5E task start | `a0dbee280b0931469780ad5fbf567343397a80b5` | FR-M04 ontology implementation |
| Phase 3C.5E end | `dca0cc197b7ea02f1715431de5edbfc655bc48a6` | Keyword ontology implemented |
| Phase 3C.5F task start | `dca0cc197b7ea02f1715431de5edbfc655bc48a6` | Final ontology + readiness audit |
| Phase 3C.5F end | `e90a5109bbb75ce2c1247be686c9a149aa554846` | Deck ready YES; FR-M04 RESOLVED |
| Phase 3D.0 task start | `e90a5109bbb75ce2c1247be686c9a149aa554846` | Evidence Engine implementation spec |
| Phase 3D.0 end | `18cfeea804cc415a8d064e2a3f9d89c611c8cb4d` | Spec READY; open decisions 0 |
| Phase 3D.0.1 task start | `18cfeea804cc415a8d064e2a3f9d89c611c8cb4d` | Spec contract hardening |
| Phase 3D.0.1 end | `379b68c0761443e641f4a8aa81c382fda0352fa4` | Spread catalog + slice LOCKED |
| Phase 3D.1A task start | `379b68c0761443e641f4a8aa81c382fda0352fa4` | Evidence domain foundation |
| Phase 3D.1A end | `620dae768d104f7ed9b8368c6b2831cec55508c3` | Evidence domain foundation |
| Phase 3D.1B task start | `620dae768d104f7ed9b8368c6b2831cec55508c3` | Structured semantic signal layer |
| Phase 3D.1B end | `9a20151986581d7ffcdb086112c3b4b802fde770` | Semantic signals |
| Phase 3D.1B.1 task start | `9a20151986581d7ffcdb086112c3b4b802fde770` | Relationship scoring calibration |
| Phase 3D.1B.1 end | `fc61bccc65f1bd523dbc3d753c5b74136586dcae` | Scoring calibration |
| Phase 3D.1B.2 task start | `fc61bccc65f1bd523dbc3d753c5b74136586dcae` | Admission consistency repair |
| Phase 3D.1B.2 end | `9d7b388e2ae3ec16a9c2b0ba5e72f6802c98b890` | Admission consistency repair |
| Phase 3D.1C task start | `9d7b388e2ae3ec16a9c2b0ba5e72f6802c98b890` | Deterministic relationship scorer + selector |
| Phase 3D.1C end | `bd5c9dcb9eabfa199eef737a66365a64c9d7b9bf` | Relationship scorer + selector |
| Phase 3D.1C.1 task start | `bd5c9dcb9eabfa199eef737a66365a64c9d7b9bf` | Selector admission/bounds/court-guard hardening |
| `release/ios-1.0` | `1b7151dca954f0cc25f39f815c0dacf0613a1164` | Build 4 — untouched |

**The authoritative current branch tip must always be obtained from `git rev-parse HEAD` / origin branch tracking — not inferred from this document.**

Updating this handoff must **not** trigger recursive commits solely to refresh a “Current HEAD” field.

---

## Repository

| Field | Value |
|---|---|
| Remote | `https://github.com/ftylmz32/oracly.git` (`ftylmz32/oracly`) |
| Active remediation branch | `fix/final-product-remediation-20260922` |
| Active worktree | `D:/oracly_final_r1` |
| Build 4 state | Untouched — `1b7151dc` on `release/ios-1.0` |

Pre-existing local noise (do **not** stage/clean):
`design/runtime/astrology_runtime.png`, generated plugin registrants, possible line-ending dirt on tests, `tool/qa/` helper scripts.

---

## Remediation completed

### R1 — Privacy / Discovery History connected-memory purge

| | |
|---|---|
| Status | **PASS** |
| Commit | `764e7b04bb43c7ae792d51d813d38ceb5dd70b94` |

### R2 — Tarot production fail-closed

| | |
|---|---|
| Status | **PASS** |
| Commit | `6fe6a74f6e1250605198b4ff8c5018d2dcebce6b` |

### R2.1 — Tarot retry-path quality bypass closure

| | |
|---|---|
| Status | **PASS** |
| Commit | `173d75228248baf32ea0d4f04fe936665efff342` |

---

## Tarot product program

| Phase | Status |
|---|---|
| Phase 0 — Forensic baseline | **COMPLETE** (read-only docs) |
| Phase 1 — Narrative product + architecture spec | **COMPLETE** (docs) |
| Phase 1.1 — Architecture contract hardening | **COMPLETE** (docs) |
| Phase 2 — Quality corpus + harness | **COMPLETE** |
| Phase 2.1 — Harness false-positive hardening | **COMPLETE** |
| Phase 3A — Major Arcana Narrative semantic foundation | **COMPLETE** |
| Phase 3B1 — Wands Minor Narrative profiles | **COMPLETE** |
| Phase 3B2 — Cups Minor Narrative profiles | **COMPLETE** |
| Phase 3B3 — Swords Minor Narrative profiles | **COMPLETE** |
| Phase 3B3.1 — CURRENT_HANDOFF project-memory restoration | **COMPLETE** (docs) |
| Phase 3B4 — Pentacles Minor Narrative profiles | **COMPLETE** |
| Phase 3C — 78-card cross-deck semantic red-team | **COMPLETE** (audit) |
| Phase 3C.1 — RT-M02 reversed-orientation remediation | **COMPLETE** |
| Phase 3C.2 — RT-M01 Cups 09/10 relationship distinction | **COMPLETE** |
| Phase 3C.3A — RT-M03 core/desire/shadow template diversification | **COMPLETE** (RT-M03 still OPEN) |
| Phase 3C.3A.1 — RT-M03A naturalness repair | **COMPLETE** (3C.3A naturalness FROZEN; RT-M03 still OPEN) |
| Phase 3C.3B — RT-M03 relationship/decision/action interaction semantics | **COMPLETE** (RT-M03 was pending 3C.4) |
| Phase 3C.4 — Final 78-card cross-deck re-audit | **COMPLETE** (audit PASS; deck readiness **NO**) |
| Phase 3C.5A — FR-B01 Magician desire EN contamination | **COMPLETE** (FR-B01 RESOLVED; readiness still **NO**) |
| Phase 3C.5B — FR-M03 shadow vs reversed court separation | **COMPLETE** (FR-M03 + RT-M02 RESOLVED; readiness still **NO**) |
| Phase 3C.5C — FR-M01 / FR-M02 EN naturalness | **COMPLETE** (FR-M01/M02 + RT-M03 minors-only; readiness still **NO** — FR-M04) |
| Phase 3C.5D — FR-M04 keyword ontology design | **COMPLETE** (design only; FR-M04 **OPEN**; readiness **NO**) |
| Phase 3C.5D.1 — FR-M04 ontology semantic mapping repair | **COMPLETE** (plan repaired; FR-M04 was OPEN) |
| Phase 3C.5E — FR-M04 canonical keyword ontology implementation | **COMPLETE** (FR-M04 was REMEDIATED — PENDING 3C.5F) |
| Phase 3C.5F — final keyword ontology + deck readiness audit | **COMPLETE** (FR-M04 **RESOLVED**; deck readiness **YES**) |
| Phase 3D.0 — Narrative Evidence Engine implementation specification | **COMPLETE** (superseded active contract by 3D.0.1) |
| Phase 3D.0.1 — Evidence Engine spec contract hardening | **COMPLETE** (spread catalog + profile slice LOCKED; OPEN **0**) |
| Phase 3D.1A — Evidence Domain Foundation | **COMPLETE** (models + slice + grounding + classical catalog; scoring **NOT** implemented) |
| Phase 3D.1B — Structured Semantic Signal Layer | **COMPLETE** (channel + DF + contrasts + transforms; scoring **NOT** implemented) |
| Phase 3D.1B.1 — Relationship scoring calibration | **COMPLETE** (docs + diagnostic; production scoring **NOT** implemented; OPEN 3D.1C decisions **0**) |
| Phase 3D.1B.2 — Admission consistency repair | **COMPLETE** (FR-F01+canonical 0.90 → REJECT; thresholds unchanged) |
| Phase 3D.1C — Deterministic Relationship Scorer + Selector | **COMPLETE** (scoring/admission/kinds/ranking/`rel_##`; builder **NOT** implemented) |
| Phase 3D.1C.1 — Selector admission/bounds/court-guard hardening | **COMPLETE** (non-theme requires normalAdmitted; max 12/10; FR minor-only) |
| Runtime Narrative Tarot Engine | **NOT IMPLEMENTED** / **NOT USER-REACHABLE** |
| Tarot Visual System (locked goldens) | **NOT IMPLEMENTED** |

### Phase 3A

| Field | Value |
|---|---|
| Status | **PASS** |
| Major profiles | **22 / 22** |

### Phase 3B1

| Field | Value |
|---|---|
| Status | **PASS** |
| Wands | **14 / 14** |

### Phase 3B2

| Field | Value |
|---|---|
| Status | **PASS** |
| Cups | **14 / 14** |

### Phase 3B3

| Field | Value |
|---|---|
| Status | **PASS** |
| Swords | **14 / 14** |
| V2 profile coverage (then) | **64 / 78** |

### Phase 3B4

| Field | Value |
|---|---|
| Status | **PASS** |
| V2 profile coverage | **78 / 78** |
| Major | **22 / 22** |
| Wands | **14 / 14** |
| Cups | **14 / 14** |
| Swords | **14 / 14** |
| Pentacles | **14 / 14** |
| Full 78-profile catalog | **COMPLETE** (exact set equality with `OraclyTarotDeck.expectedIds`) |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| Canonical deck | Unchanged (78 / 22 / 56) |
| Current Tarot user path | Unmodified |

### Phase 3C

| Field | Value |
|---|---|
| Status | **PASS** (audit complete) |
| Profiles reviewed | **78 / 78** |
| Report | `docs/product/tarot/TAROT_78_PROFILE_RED_TEAM.md` |
| BLOCKER | **0** |
| MAJOR | **3** (RT-M01 cups_09/10 rel · RT-M02 shadow≈reversed · RT-M03 template monotony) |
| MINOR | **6** |
| INFO | **5** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** (unchanged) |

### Phase 3C.1

| Field | Value |
|---|---|
| Status | **PASS** |
| RT-M02 | **RESOLVED** |
| RT-M01 | **OPEN** |
| RT-M03 | **OPEN** |
| Initial exact shadow↔reversed clones | **19** |
| Initial high-similarity (≥0.75) | **9** |
| Profiles changed | **36** (`reversed.expression` only) |
| Transform assignments changed | **NONE** |
| Final exact clones | **0** |
| Unresolved semantic near-clones | **0** |
| DECK READY FOR EVIDENCE ENGINE | **NO** (RT-M01 + RT-M03 still open) |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.2

| Field | Value |
|---|---|
| Status | **PASS** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **OPEN** |
| Fields changed | `cups_09.relationshipDynamic` · `cups_10.relationshipDynamic` |
| Before similarity | **≈ 0.77** |
| After similarity | **0.107** |
| Blind-swap | **NO / NO** |
| DECK READY FOR EVIDENCE ENGINE | **NO** (RT-M03 still open) |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.3A

| Field | Value |
|---|---|
| Status | **PASS** (part 1 only; metrics green; naturalness later repaired in 3C.3A.1) |
| Fields in scope | `coreMeaning` · `desire` · `shadow` |
| Profiles touched | **78** |
| coreMeaning changed | **62** (EN) |
| desire changed | **78** (EN) |
| shadow changed | **47** (EN) |
| Top opener share (all target × locales) | **≤ 25%** |
| Replacement monoculture | **NO** (mechanical gate); residual scaffold rotation repaired in **3C.3A.1** |
| Historical EN stems (`It speaks of` / wish / slide) | **62→0** / **78→0** / **47→0** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** (shadow↔reversed exact clones=0) |
| RT-M03 | **PARTIALLY REMEDIATED / OPEN** (interaction fields not yet remediated) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.3A.1

| Field | Value |
|---|---|
| Status | **PASS** |
| 3C.3A naturalness quality | **FROZEN** |
| Fields changed | EN `coreMeaning` / `desire` / `shadow` only |
| Profiles changed | **77** |
| coreMeaning.en | **44** |
| desire.en | **73** |
| shadow.en | **33** |
| TR/RU fields changed | **NONE** |
| Replacement scaffolds cleared | At the center / meaning turns on / Part of this archetype / At the edge… → **0** |
| Known stilted / fragmentary / template-swap remaining | **0** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **PARTIALLY REMEDIATED / OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.3B

| Field | Value |
|---|---|
| Status | **PASS** |
| Fields in scope | `relationshipDynamic` · `decisionDynamic` · `actionDirection` |
| Profiles touched | **75 / 78** |
| relationshipDynamic changed | **53** |
| decisionDynamic changed | **74** |
| actionDirection changed | **52** |
| TR/EN/RU field changes | **179 / 179 / 179** |
| Historical EN stems | `the choice` 60→0 · `asks to separate` 39→0 · `in a bond` 52→2 · `do not` 62→5 |
| Self-caught replacement monoculture | "worth telling/keeping apart" / "не то же самое" family peaked ~31% of touched relationship fields mid-pass; corrected to 14.8% via a second rewrite pass on 9 cards |
| High-similarity candidates (Jaccard ≥0.5) | 9→0 |
| `cups_03`/`cups_10` decisionDynamic (RT-m01) | 0.643→0.161, **RESOLVED** |
| `pentacles_13` same-card role redundancy | 0.50→0, **RESOLVED** |
| RT-m05 action clustering | `name` 15.4% share both before/after — **lexical-only, non-semantic** |
| RT-M01 | **RESOLVED** (untouched, regression-tested) |
| RT-M02 | **RESOLVED** (untouched, regression-tested) |
| RT-M03 | **REMEDIATED — PENDING FINAL RE-AUDIT** |
| DECK READY FOR EVIDENCE ENGINE | **NO** — Phase 3C.4 independent re-audit required |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |
| Canonical deck | Unchanged |
| Current Tarot user path | Unmodified |

### Phase 3C.4

| Field | Value |
|---|---|
| Status | **PASS** (audit complete) |
| Report | `docs/product/tarot/TAROT_78_PROFILE_FINAL_REAUDIT.md` |
| Profiles reviewed | **78 / 78** |
| BLOCKER | **1** |
| MAJOR | **4** |
| MINOR | **4** |
| INFO | **4** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |
| Production profiles modified | **NO** |

### Phase 3C.5A

| Field | Value |
|---|---|
| Status | **PASS** |
| FR-B01 | **RESOLVED** |
| Field changed | `major_01.desire.en` only |
| TR / RU changed | **NO** / **NO** |
| CLEAR-DRIFT from FR-B01 | **0** after remediation |
| Canonical fidelity (`major_01`) | **FAITHFUL** |
| FR-M01 | **OPEN** |
| FR-M02 | **OPEN** |
| FR-M03 | **OPEN** |
| FR-M04 | **OPEN** |
| RT-M02 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.5B

| Field | Value |
|---|---|
| Status | **PASS** |
| FR-B01 | **RESOLVED** |
| FR-M03 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| Profiles changed | **5** — `cups_11`, `swords_11`, `swords_13`, `swords_14`, `wands_11` |
| Field changed | `reversed.expression` TR/EN/RU only |
| Transform assignments | **NONE** changed |
| cups_10 / pentacles_10 edited | **NO** |
| Human near-clones in audited FR-M03 scope | **0** |
| Exact shadow↔reversed clones | **0** |
| FR-M01 | **OPEN** |
| FR-M02 | **OPEN** |
| FR-M04 | **OPEN** |
| RT-M03 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.5C

| Field | Value |
|---|---|
| Status | **PASS** |
| FR-B01 | **RESOLVED** |
| FR-M01 | **RESOLVED** |
| FR-M02 | **RESOLVED** |
| FR-M03 | **RESOLVED** |
| RT-M01 | **RESOLVED** |
| RT-M02 | **RESOLVED** |
| RT-M03 | **RESOLVED — NON-BLOCKING MINORS REMAIN** |
| Profiles changed | `swords_09`, `cups_10` |
| EN fields changed | swords_09: light/desire/upright.expression/reversed.expression · cups_10: coreMeaning/desire/relationshipDynamic |
| TR / RU | **Unchanged** |
| keywordIds | **Unchanged** |
| FR-M04 | **OPEN** |
| DECK READY FOR EVIDENCE ENGINE | **NO** — FR-M04 blocks |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3C.5D

| Field | Value |
|---|---|
| Status | **PASS** (design only) |
| FR-M04 | **OPEN** — implementation pending |
| Ontology plan | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md` |
| Current unique / singleton | **397** / **352** (**88.66%**) |
| Proposed lexicon | **124** defined · projected used **118** |
| Projected singleton % | **24.58%** |
| Full 78×orientation mapping | **COMPLETE** |
| Migration table | **COMPLETE** |
| Ambiguous mappings | `envy` (+ review notes) |
| Production keywordIds changed | **NO** |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Tarot Visual System | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

### Phase 3D.1C.1

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Defect | Higher-priority kind bypassed `normalAdmitted` in selector `_finalize` |
| Repair | Non-theme emit requires `normalAdmitted`; theme sole special admission |
| Max relationships | Hard clamp requested max to **[0, 12]** |
| Max cards | Absolute ceiling **10** → else `cardCountMismatch` |
| FR court guards | Minor suits only — `OraclyTarotSuit.none` never true |
| Scoring constants / kind precedence | **UNCHANGED** |
| NarrativeEvidenceBuilder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |

### Phase 3D.1C

| Field | Value |
|---|---|
| Status | **COMPLETE** / **PASS** |
| Scorer | **IMPLEMENTED** — `NarrativeRelationshipScorer` over prepared contexts |
| Selector | **IMPLEMENTED** — C(n,2) · kind finalization · theme · top-12 · `rel_##` |
| Overlap | `Σ(weight/6)` |
| Contradiction | **kind/veto only** — **NO** numeric −0.60 |
| FR-F01/F02 | overlap cap 0.35 · strength cap 0.45 — **NO** separate FR penalty |
| Support fallback | `normalAdmitted` + SEMANTIC; reinforcement = ≥2 ids df<8 AND mean raw weight ≥4.0 |
| Theme echo | current-spread selector only · max **1** · HF-only **REJECT** |
| Top-N / evidence ids | **12** · `rel_01`…`rel_12` deterministic |
| NarrativeEvidenceBuilder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| AI / Memory / Network / Persistence | **0** / **NONE** / **0** / **0** |

### Phase 3D.1B.2

| Field | Value |
|---|---|
| Status | **PASS** |
| Defect | FR-F01 + canonical S=0.90 incorrectly labeled admitted |
| Correct result | **REJECT** (canonical threshold ≥1.0 unchanged) |
| FR-F02 + supportive 0.65 | **REJECT** |
| Synthetic guarded admit | 0.35+0.55+0.40=**1.30** · strength≈**0.371** ≤0.45 |
| Weak-band example | 1 HF + canonical (~1.11–1.19) |
| Scoring constants changed | **NO** |
| Production source | **UNCHANGED** |
| Open 3D.1C scoring decisions | **0** |
| Spec ready for 3D.1C | **YES** |

### Phase 3D.1B.1

| Field | Value |
|---|---|
| Status | **PASS** — calibration complete · OPEN 3D.1C scoring decisions **0** |
| Kind | Docs + optional test-only diagnostic — **no production scorer** |
| Calibration doc | `docs/product/tarot/NARRATIVE_RELATIONSHIP_SCORING_CALIBRATION.md` |
| Raw IDF saturation | **CONFIRMED** (single-id min ≈3.35; 93% overlapping pairs raw ≥3.5) |
| Chosen overlap | `Σ (weight(id)/6.0)` over Chan∩ |
| Normalized id range | ≈ **0.558 → 0.894** (used) |
| Theme echo threshold | **Keep 2.0** (normalized) |
| Tag-only / orientation / question | 0 numeric · 0 alone · {0,+0.15} |
| FR-F01/F02 identity | **`keywordIds` set equality** |
| Production scoring | **NOT IMPLEMENTED** |
| Evidence builder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| Spec ready for 3D.1C | **YES** (after 3D.1B.2 admission example repair) |

### Phase 3D.1B

| Field | Value |
|---|---|
| Status | **COMPLETE** |
| Implemented | `NarrativeSemanticChannel` · FR-F04 dedupe · frozen ontology-rev1 DF map · keyword discrimination weights · explicit contrast table · transform signal/suppression helper |
| Ontology revision / N / DF ids | **1** · **156** · **128** |
| scatter / haste df | **14** / **13** (catalog truth; stale prompt 14 for haste WITHDRAWN) |
| keyword∩symbolTag orientations | **64 / 156** |
| Contrast pairs | **11** HARD + **4** CONTEXTUAL = **15** |
| Scoring | **NOT IMPLEMENTED** |
| FR-F01 / FR-F02 pair guards | **NOT IMPLEMENTED** — Phase 3D.1C |
| Evidence builder | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| AI / Persistence | **0** / **0** |
| Narrative evidence tests | **64** passed |
| Full Flutter | **3832** passed · **0** failed · **15** skipped · **0** timed out |

### Phase 3D.1A

| Field | Value |
|---|---|
| Status | **COMPLETE** |
| Implemented | Evidence domain models · `TarotNarrativeProfileSlice` · question grounding · classical spread semantic catalog · typed errors · empty memory/recurrence shells · `RequestBounds` / `TarotNarrativeRequest` |
| Spreads / positions | **5 / 5** · **26** |
| Authoritative edges / projected | **29** · **45** (13 directed + 16×2) |
| Position weights | **all 1.0** |
| Scoring | **NOT IMPLEMENTED** |
| Evidence builder | **NOT IMPLEMENTED** |
| Relationship candidate generation | **NOT IMPLEMENTED** |
| User path | **UNCHANGED** |
| AI calls | **0** |
| Persistence | **0** |
| Memory / recurrence providers | **NOT IMPLEMENTED** |
| Production surface | `lib/features/tarot/narrative/evidence/` |
| Tests | `test/features/tarot/narrative_evidence/` (**38** passed at 3D.1A) |
| Full Flutter | **3806** passed · **0** failed · **15** skipped · **0** timed out |

### Phase 3D.0.1

| Field | Value |
|---|---|
| Status | **PASS** — contract hardening |
| Resolved | Spread semantics completeness · `TarotNarrativeProfileSlice` architecture |
| Spreads / positions / edges | **5 / 5** · **26** rows · **29** edges |
| Position weights | **all 1.0** |
| Open implementation decisions | **0** |
| Spec ready for 3D.1A | **YES** |
| Evidence Engine | **NOT IMPLEMENTED** |
| Deck ready | **YES** |
| Production modified | **NO** |

### Phase 3D.0

| Field | Value |
|---|---|
| Status | **COMPLETE** — base spec; active contract = **3D.0.1** |
| Spec | `docs/product/tarot/NARRATIVE_EVIDENCE_ENGINE_IMPLEMENTATION_SPEC.md` |
| Deck readiness | **YES** (from 3C.5F) |
| Evidence Engine | **NOT IMPLEMENTED** |
| Open implementation decisions | **0** (after 3D.0.1) |
| Current user path | **UNCHANGED** |
| AI calls | **0** |
| Memory / recurrence | **DEFERRED Phase 4** |
| Signature spreads | **DEFERRED Phase 5** |
| AI narrative | **DEFERRED Phase 6** |
| Visual | **DEFERRED Phase 7** |
| Production modified | **NO** |

### Phase 3C.5F

| Field | Value |
|---|---|
| Status | **PASS** (independent audit) |
| Profiles / orientations | **78 / 78** · **156 / 156** |
| FR-M04 | **RESOLVED** |
| BLOCKER / MAJOR / MINOR / INFO | **0 / 0 / 3 / 2** |
| Semantic inversion / loss | **0 / 0** |
| Engine-blocking false overlaps | **0** |
| Unsupported keyword concepts | **0** |
| Engine usage contract | **READY** |
| DECK READY FOR EVIDENCE ENGINE | **YES** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Visual System | **NOT IMPLEMENTED** |
| Audit doc | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_FINAL_AUDIT.md` |
| Production modified | **NO** |

### Phase 3C.5E

| Field | Value |
|---|---|
| Status | **PASS** (implementation) |
| FR-M04 | was **REMEDIATED — PENDING 3C.5F** (now RESOLVED via 3C.5F) |
| Keyword ontology | **IMPLEMENTED** |
| Ontology revision | **1** |
| Defined / used ids | **128 / 122** |
| Assignments / singletons | **439 / 30 (24.59%)** |
| Orientations mapped | **156 / 156** |
| Appendix B fixture match | **156 / 156** |
| Prose / transforms / symbolTags / profileRevision | **UNCHANGED** |
| DECK READY FOR EVIDENCE ENGINE | was **NO** pending 3C.5F |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Visual System | **NOT IMPLEMENTED** |

### Phase 3C.5D.1

| Field | Value |
|---|---|
| Status | **PASS** (design repair) |
| FR-M04 | was **OPEN** — implementation pending |
| Ontology plan | `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md` (**ACTIVE = 3C.5D.1**, implemented in 3C.5E) |
| Ambiguous mappings | **0** |
| Semantic inversions after | **0** |
| Plan approved for implementation | **YES** |
| Production keywordIds changed | **NO** (design phase) |
| DECK READY FOR EVIDENCE ENGINE | **NO** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| V2 profile coverage | **78 / 78** |

Production surface:

- `lib/features/tarot/narrative/domain/` — models + validator + symbol tags
- `lib/features/tarot/narrative/data/` — catalog + Major + Wands + Cups + Swords + Pentacles profiles
- Tests: `test/features/tarot/narrative_domain/` (+ `red_team/`)

### Spec artifacts

- `docs/product/tarot/NARRATIVE_TAROT_SPEC.md`
- `docs/product/tarot/NARRATIVE_TAROT_DATA_CONTRACT.md`
- `docs/product/tarot/NARRATIVE_TAROT_MIGRATION_PLAN.md`
- `docs/product/tarot/NARRATIVE_TAROT_QUALITY_STANDARD.md`
- `docs/product/tarot/TAROT_PHASE0_FORENSIC_BASELINE.md`
- `docs/product/tarot/TAROT_78_PROFILE_RED_TEAM.md`
- `docs/product/tarot/TAROT_KEYWORD_ONTOLOGY_PLAN.md`

### Phase 2 artifacts

- Canonical corpus: `test/fixtures/narrative_tarot_v2_corpus.json`
- CONTRACT HARNESS (test-only): `test/support/narrative_tarot_v2/`
- Tests: `test/features/tarot/narrative_v2/`
- Legacy corpus retained: `test/fixtures/interpretation_engine_v2_corpus.json` (historical / insufficient for Narrative Tarot V2; not deleted)

---

## Latest verified baselines

| Suite | Result |
|---|---|
| Flutter (at code baseline `173d7522`) | 3627 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3A — PL-T3A) | 3662 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B1 — PL-T3B1) | 3669 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B2 — PL-T3B2) | 3676 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B3 — PL-T3B3) | 3685 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3B4 — PL-T3B4) | 3699 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.1 — PL-T3C.1) | 3715 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.2 — PL-T3C.2) | 3719 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.3A — PL-T3C.3A) | 3725 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.3A.1 — PL-T3C.3A.1) | 3728 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.3B — PL-T3C.3B) | 3737 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.4 — PL-T3C.4) | docs/test-only; production source unmodified |
| Flutter (Phase 3C.5A — PL-T3C.5A) | 3740 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.5B — PL-T3C.5B) | 3749 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.5C — PL-T3C.5C) | 3756 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3C.5D — PL-T3C.5D) | docs + diagnostic only; production source unmodified |
| Flutter (Phase 3C.5D.1 — PL-T3C.5D.1) | docs only; production source unmodified |
| Flutter (Phase 3C.5E — PL-T3C.5E) | 3768 passed · 0 failed · 15 skipped · 0 timed out |
| Flutter (Phase 3D.1A — PL-T3D.1A) | 3806 passed · 0 failed · 15 skipped · 0 timed out (+38 evidence domain) |
| Flutter (Phase 3D.1B — PL-T3D.1B) | 3832 passed · 0 failed · 15 skipped · 0 timed out (+26 semantic signals) |
| Backend (known) | 658 passed · 0 failed · 1 skipped |

---

## Open canonical backlog (NOT completed)

### P1

- Yildizname / Birth Chart: exact time/place collected; chart core is Sun-sign-only
- Astrology: LOCAL catalogue/sun-sign behavior vs LIVE registry mismatch
- Universe Map Memory chamber: reachable legacy CRUD/admin-feeling UI
- Home / Daily Ritual: inverse text-size accessibility behavior
- Premium: cancel/pending/restore-none uses success-style snackbar

### Release proof

Coffee production E2E · Palm production E2E · SoulMate production E2E · real/sandbox iOS StoreKit monthly/yearly purchase · restore · server entitlement verification

These remain **NOT COMPLETE** unless later evidence proves otherwise.

---

## Next action

**ChatGPT review before Phase 3D.1D** (full `NarrativeEvidenceBuilder` + fixed corpus).

Phase 3D.1C.1: **PASS** · higher-priority admission bypass **FIXED** · theme exception preserved · maxRelationships hard cap **12** · max cards **10** · FR court guards minor-only · Builder **NOT** implemented · User path **UNCHANGED**.

Do **not** start 3D.1D until reviewed.
Do **not** mark future items completed until verified.
Do **not** merge.
Do **not** modify `release/ios-1.0` / Build 4.
