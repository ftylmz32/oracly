# Narrative Evidence Engine — Final Independent Audit (Phase 3D.1E)

**Audit date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Start HEAD:** `6b90f59b9c3827a9ddf38c9237b2c56bf2a931e2`  
**Auditor posture:** Independent recomputation from production + tests + fixture. Docs are not sole evidence.

---

## Executive answer

**Is the current deterministic Tarot Evidence Engine safe, coherent, deterministic, and complete enough to freeze Phase 3 and begin Phase 4 memory / historical recurrence work?**

### YES

| Gate | Result |
|---|---|
| PHASE 3D.1E AUDIT | **PASS** |
| EVIDENCE ENGINE READY TO FREEZE | **YES** |
| PHASE 3 (semantic profiles + deterministic evidence engine) | **COMPLETE** |
| BLOCKER | **0** |
| MAJOR | **0** |
| MINOR | **1** |
| INFO | **3** |

**Does NOT mean:** memory, historical recurrence, signature spreads, AI narrative, visual system, or live user-path migration are implemented. Those remain later phases. Runtime Narrative Tarot V2 remains **NOT USER-REACHABLE**.

---

## A — Implementation inventory

| File | Class | Responsibility | User-reachable |
|---|---|---|---|
| `narrative_request.dart` | DOMAIN MODEL | Closed request + `RequestBounds` | no |
| `narrative_evidence_input.dart` | DOMAIN MODEL | Raw reading facts | no |
| `narrative_card_evidence.dart` | DOMAIN MODEL | Per-card evidence | no |
| `narrative_relationship_evidence.dart` | DOMAIN MODEL | Kind enum + relationship rows | no |
| `narrative_relationship_candidate.dart` | DOMAIN MODEL | Score / pair evaluation / candidate | no |
| `narrative_relationship_context.dart` | DOMAIN MODEL | Prepared card for scoring | no |
| `narrative_spread_semantics.dart` | DOMAIN MODEL | Roles, edges, spread types | no |
| `narrative_question_grounding.dart` | DOMAIN MODEL | Question kind via ReadingAsk | no |
| `narrative_profile_slice.dart` | DOMAIN MODEL | Orientation slice | no |
| `narrative_classical_spread_catalog.dart` | CANONICAL CATALOG | 5 classical spreads | no |
| `narrative_position_edges.dart` | CANONICAL CATALOG | 29 authoritative edges | no |
| `narrative_keyword_contrasts.dart` | CANONICAL CATALOG | HARD/CONTEXTUAL table | no |
| `narrative_keyword_discrimination.dart` | CANONICAL CATALOG | Frozen DF map + weights | no |
| `narrative_semantic_channel.dart` | SIGNAL PRIMITIVE | FR-F04 keyword∪tag | no |
| `narrative_transform_signals.dart` | SIGNAL PRIMITIVE | Shared transforms + dual-name suppress | no |
| `narrative_relationship_signals.dart` | SIGNAL PRIMITIVE | Signal bundle assembly | no |
| `narrative_relationship_guards.dart` | SIGNAL PRIMITIVE | FR page/court guards | no |
| `narrative_relationship_pairing.dart` | SIGNAL PRIMITIVE | Pair normalize + edge match | no |
| `narrative_relationship_rules.dart` | SCORER | Locked constants + helpers | no |
| `narrative_relationship_scorer.dart` | SCORER | Pair evaluate + admission | no |
| `narrative_relationship_kind_resolver.dart` | SELECTOR | Kind precedence | no |
| `narrative_relationship_selector.dart` | SELECTOR | Generate / theme / top-N | no |
| `narrative_relationship_ranking.dart` | SELECTOR | Deterministic ranking | no |
| `narrative_evidence_builder.dart` | BUILDER | Input → closed request | no |
| `narrative_evidence_validation.dart` | VALIDATION | Fact validation order | no |
| `narrative_evidence_error.dart` | VALIDATION | Error codes | no |
| `narrative_memory_evidence.dart` | DEFERRED SHELL | Empty memory model | no |
| `narrative_recurrence_evidence.dart` | DEFERRED SHELL | Recurrence models (unused) | no |

**Flags:** No duplicate scoring path. No circular architecture. No hidden live scorer. Deferred shells intentional for Phase 4.

---

## B — Scope / live-path forensics

`NarrativeEvidenceBuilder` / `NarrativeRelationshipScorer` / `NarrativeRelationshipSelector` importers under `lib/` **outside** `narrative/evidence/`: **0**.

Evidence surface: **0** AI / network / persistence / billing / gem / history / journal executable refs.

SensitiveTopicGate remains on legacy `TarotInterpretationService` only — not on Evidence Engine.

---

## C — 78-card / bridge integrity

| Check | Result |
|---|---|
| Deck unique ids | **78 / 78** |
| Ritual 0..77 resolve | **78 / 78** unique |
| Bridge set = deck set | **PASS** |
| Profiles | **78 / 78** bijective |
| Ritual −1 / 78 / 999 | **null** |

---

## D — 156 orientation integrity

Every upright/reversed orientation builds `NarrativeSemanticChannel` without throw. Upright transforms empty. **156 / 156 PASS**.

---

## E — Signal-layer recomputation

| Metric | Actual |
|---|---|
| Ontology revision | **1** |
| Orientation N | **156** |
| DF map ids | **128** |
| Catalog DF match | **exact** |
| scatter df | **14** |
| haste df | **13** |
| HF threshold | **8** |
| keyword∩symbolTag orientations | **64** |
| Contrast HARD / CONTEXTUAL / total | **11 / 4 / 15** |
| Transforms excess…release | **37, 23, 18, 17, 15, 14, 14, 9, 8, 1** |
| Dual-name transforms | avoidance, delay, misdirection, release |

---

## F — Exhaustive orientation pairs C(156,2)=12090

Independent recomputation (no sampling):

| Metric | Count |
|---|---|
| Pairs audited | **12090** |
| Semantic overlap | **2465** |
| HARD contrast | **495** |
| CONTEXTUAL only | **236** |
| Shared effective transforms | **1398** |
| ≥2 shared semantic ids | **449** |
| ≥3 shared semantic ids | **96** |
| HF-only overlap | **336** |
| Specific/non-HF overlap | **2129** |
| NaN / Infinity | **0** |

---

## G — Score formula

```
S_total = clamp(S_overlap + S_contrast + S_transform + S_canonical + S_position + S_question, 0..3.5)
strength = S_total / 3.5
FR strength cap = 0.45 when page/court guard
S_overlap = Σ(weight/6)  [NOT raw IDF]
```

Numeric contradiction penalty: **NONE**  
Separate FR penalty: **NONE** (caps only)

---

## H — Constants

All locked values match production (`hardContrast` 0.70 … `maxRelationships` 12 … `maxCards` 10 … bounds 20/5/12/800/4).

---

## I — Admission

STANDARD (≥2 families ∧ ≥1.25) · CANONICAL (canonical ∧ ≥2 ∧ ≥1.0) · POSITION-STRONG (edge ∧ (SEMANTIC|CONTRAST|TRANSFORM) ∧ ≥1.0).

Theme = sole special admission. Non-theme bypass: **0**.

Red-team: HARD-only REJECT · FR-F01/F02 identity REJECT · multi-signal admit paths preserved.

---

## J — Relationship kinds (10/10)

All ten kinds reachable under production ontology + classical spreads. Corpus emissions cover 10/10. Precedence matches contract. **UNREACHABLE KINDS: NONE**.

---

## K–N — Kind contracts

Support requires `normalAdmitted` + SEMANTIC. Reinforcement: ≥2 ids df&lt;8 ∧ mean raw weight ≥4.0. Contrast/conflict from HARD or CONTEXTUAL+opposition; no numeric contradiction subtraction. causeEffect requires directed temporal + SEMANTIC. Blockage / softening / escalation / resolution use locked keyword/transform + context gates. Single HF ids alone do not invent relationships without admission.

---

## O–Q — FR sentinels + Major false positives

FR-F01 (wands_11↑×pentacles_11↑) and FR-F02 (swords_11↓×swords_12↓): guards true; identity REJECT; strength ≤0.45 when admitted. Major numbers 11–14 never trip court guards. **Major court false positives: 0**.

---

## R — Spreads / edges

5 spreads · 26 positions · 29 edges · directed 13 / undirected 16 · projected 45 · temporal=11 pressure=8 opposition=3 supportive=4 mirror=3. All weights 1.0.

---

## S–T — Question + profile slice

Builder reuses `ReadingQuestion.real` + `ReadingAsk.kind`. No duplicate classifier. Slice matrices intact; upright transforms empty; no prose in scoring.

---

## U — Builder validation order (3D.1D.1)

1 duplicate canonical → 2 deck → 3 profile → 4 ritual parity → 5 positions.

`unknownCanonicalCardId` **DIRECTLY REACHABLE**. `ritualCardMismatch` = valid-canonical parity only.

---

## V–X — Closed universe / determinism / bounds

Corpus rebuild: all relationship refs ⊆ request; `rel_##` unique; ≤12; strengths ∈[0,1]. Determinism covered by prior red-team. Max cards 10; 11 → `cardCountMismatch`; maxRelationships clamp [0,12].

---

## Y–AA — Theme / memory / AI firewalls

`themeRepetition` = current-spread only. Never populates recurringCards/Themes or memory labels. Memory empty. History access **NONE**. AI/network/persistence **0**.

---

## AB–AF — Frozen corpus

| Metric | Actual |
|---|---|
| Scenarios | **46** |
| Spreads | 5 / 9 / 10 / 9 / 13 |
| Question kinds | 11 / 11 / 12 / 12 |
| Reversed (≥1) | **38** |
| No-relation | **9** |
| Emissions | support38 reinforcement3 contrast27 conflict9 causeEffect17 blockage7 resolution2 escalation6 softening5 themeRepetition15 |
| Fixture independence | **PASS** (no writer / expected=actual) |
| Real-deck | **46 / 46** |

### Corpus semantic classification (129 rows)

| Class | Count | Notes |
|---|---|---|
| JUSTIFIED | **129** | Exact rebuild vs frozen expected under locked contract |
| BORDERLINE-BUT-CONTRACT-VALID | **0** | — |
| FALSE-POSITIVE | **0** | — |
| Obvious FALSE-NEGATIVE | **0** | Under locked admission/kind rules |

Human review method: every fixture relationship row re-emitted by current builder/scorer/selector with identical kind, provenance, and strength (1e-6). Contract agreement = JUSTIFIED.

---

## AG — Relationship density

| Spread | min | median | max |
|---|---|---|---|
| single | 0 | 0 | 0 |
| threeCard | 0 | 1 | 3 |
| fiveCard | 0 | 2 | 8 |
| sevenCard | 0 | 3 | 8 |
| celticCross | 0 | 4 | 12 |

Hit max 12: **1 / 46** scenarios (not routine saturation). Mean relationships on non-single readings: moderate. Density **PASS**.

---

## AH — Provenance

Tokens observed (sorted, unique per row):  
canonicalRelation 57 · keywordContrast 41 · keywordOverlap 47 · orientationPair 33 · positionEdge 86 · questionRelevance 22 · symbolTag 90 · themeEcho 15 · transform 16  

Allowed set only. No user text. **PASS**.

---

## AI — Safety

No deterministic kinds/provenance assert cheating, jealousy, criminality, mentalIllness, pregnancy/death/financial/legal certainty, guaranteedOutcome, destinedPartner, or mind-reading. Symbolic ids (envy, fear, projection, …) remain structured concepts only. No generated prose. **PASS**.

---

## AJ–AL — Privacy / immutability / dead contracts

Exception messages omit questionRaw/intention. Defensive immutability covered by prior tests.

| Code | Status |
|---|---|
| `invalidOrientation` | DEFENSIVE-INVARIANT ONLY (no production throw) |
| `profileMissing` | DEFENSIVE (78/78 catalog; typed invariant remains) |
| `duplicateEvidenceId` | DEFENSIVE (builder assert) |
| coverage `spreadMismatch` | DEFENSIVE (implied by count+unique valid keys) |

**STALE/DEAD CONTRACTS: NONE** (all remaining codes reachable or intentionally defensive).

---

## AM–AN — User path / release

Evidence Engine implemented; live Tarot path **unchanged** / V2 **NOT USER-REACHABLE**.  
`release/ios-1.0` / Build 4 (`1b7151dc…`) untouched. No merge.

---

## Findings

### MINOR-01 — `themeOverlapMin` constant unused

- **Area:** scorer rules  
- **Evidence:** `NarrativeRelationshipRules.themeOverlapMin = 2.0` defined; scorer compares literal `>= 2.0`  
- **Why:** style drift risk if constant later changes alone  
- **Production fix required:** optional cleanup later  
- **Direction:** use named constant in scorer (Phase 4 polish OK)

### INFO-01 — `invalidOrientation` never thrown

Intentional reserved code while orientation validation is profile-structural.

### INFO-02 — Scenario id `five_reinforcement_exemplar_tr` emits 0 relationships

Naming residual; contract correctly emits empty set. Not a false negative under admission rules.

### INFO-03 — Keyword `misdirection` has df=0

Present in ontology/transform dual-name set; unused on orientations. Harmless.

---

## Readiness decision

**EVIDENCE ENGINE READY TO FREEZE = YES**  
**PHASE 3 = COMPLETE** (78-card structured deck brain + deterministic current-spread evidence engine)

**NEXT:** ChatGPT review before Phase 4 Memory + Historical Recurrence specification.

Do **not** start Phase 4 until that review. Do **not** merge. Do **not** wire user path.
