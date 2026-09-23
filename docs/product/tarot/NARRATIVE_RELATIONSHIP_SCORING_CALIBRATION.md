# Narrative Relationship Scoring Calibration

**Phase:** 3D.1B.1  
**Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Start SHA:** `9a20151986581d7ffcdb086112c3b4b802fde770`  
**Authority after review:** binds Phase **3D.1C** scoring implementation  
**Production scorer:** **NOT IMPLEMENTED** (this document is audit / contract only)

Diagnostic test (test-only helpers):  
`test/features/tarot/narrative_evidence/red_team/narrative_relationship_scoring_calibration_test.dart`

---

## 1 — Executive decision

| Decision | Lock |
|---|---|
| Raw `sum(w)` overlap | **UNSAFE — REJECT** |
| Chosen overlap | **B — NORMALIZED IDF** |
| Formula | `S_overlap = Σ (weight(id) / 6.0)` over `Chan(A) ∩ Chan(B)` |
| Per-id normalized range (rev 1, used ids) | **≈ 0.558 → 0.894** (df=0 clamp → 1.0 unused) |
| Theme echo threshold | **Keep `S_overlap ≥ 2.0`** under normalized formula |
| Tag-only motifs | **0 numeric**; provenance/tie only |
| Question bonus | **0 or +0.15**; open = 0; guidance = 0 |
| Orientation family G | **0 numeric · 0 family alone** |
| FR-F01/F02 identity | **`keywordIds` set equality** (not full semantic Chan) |
| OPEN 3D.1C SCORING DECISIONS | **0** |
| Spec ready for 3D.1C | **YES** |

---

## 2 — Why raw IDF saturation is unsafe

Locked raw weight:

```
w(id) = ln((156+1)/(df(id)+1)) + 1
clamp(w, 1.0, 6.0)
```

Revision-1 production (used ids, df ≥ 1):

| Metric | Value |
|---|---:|
| min w | **3.348** (scatter, df=14) |
| max w | **5.363** (df=1 used) |
| median w | **4.670** |
| mean w | **4.671** |
| df=0 clamp | **6.0** (unused ontology ids; never appear in pairs) |

Planned `S_total ∈ [0, 3.5]`.

A **single shared keyword** already contributes **≥ 3.35** raw — nearly saturating the entire score before contrast, transform, position, canonical, or question terms.

Exhaustive pair proof (§3) shows **100%** of overlapping pairs have raw `S_overlap ≥ 3.0`, and **93.35%** already `≥ 3.5`. Raw overlap alone collapses strength bands and makes other families numerically irrelevant.

**RAW IDF SATURATION: CONFIRMED.**

---

## 3 — Exhaustive 12,090-pair metrics

Universe:

| Item | Count |
|---|---:|
| Profiles | 78 |
| Orientations | 156 |
| Unordered pairs `C(156,2)` | **12090** |
| Pairs with ≥1 shared semantic id | **2465** |
| keyword∩symbolTag orientations | **64 / 156** |
| Ontology ids / DF map | **128** |
| scatter / haste df | **14 / 13** |

### 3.1 Discrimination extremes (used ids)

**Top 10 highest discrimination (lowest df among used):**  
`principle`, `attachment`, `authority`, `awakening`, `bias`, `intuition`, `conformity`, `wisdom`, `coordination`, `courage` (all df=1 → w≈5.363)

**Top 10 lowest discrimination (highest df):**  
scatter:14 · haste:13 · withdrawal:13 · escape:10 · control:9 · delay:9 · isolation:9 · display:8 · fear:8 · doubt:7

### 3.2 RAW `S_overlap = Σ w(id)` (overlapping pairs only)

| Slice | n | min | p25 | median | p75 | p90 | p95 | max | ≥3.5 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| ALL | 2465 | 3.348 | 4.110 | 4.447 | 4.958 | 8.934 | 9.810 | 20.354 | **93.35%** |
| 1 shared id | 2016 | 3.348 | 4.110 | 4.264 | 4.670 | 4.958 | 5.363 | 5.363 | 91.87% |
| 2 shared | 353 | 6.765 | 8.241 | 8.780 | 9.222 | 9.810 | 10.321 | 10.726 | 100% |
| 3+ shared | 96 | 10.876 | 13.094 | 13.738 | 14.480 | 15.278 | 16.089 | 20.354 | 100% |
| HF-only | 336 | 3.348 | 3.417 | 3.658 | 3.754 | 3.859 | 6.765 | 7.613 | 51.19% |
| all-specific | 2027 | 3.977 | 4.264 | 4.447 | 4.958 | 8.934 | 10.033 | 20.354 | 100% |

Also: **100%** of overlapping pairs have raw ≥ 1.0, ≥ 1.25, ≥ 2.0, and ≥ 3.0.

**RAW SINGLE-ID MIN = 3.348** (scatter).

---

## 4 — Candidate formulas compared

| ID | Formula | Verdict |
|---|---|---|
| **A RAW** | `Σ w` | **REJECT** — saturates `[0,3.5]` |
| **B NORMALIZED** | `Σ (w/6)` | **ACCEPT — CHOSEN** |
| **C MEAN×count** | `mean(w/6)×|shared|` | **Identical to B** — not a distinct candidate |
| **D SATURATING** | `1−exp(−Σ(w/6))` | Reject as primary — compresses multi-id signal (max≈0.966); useful only as optional future softener, not now |

---

## 5 — Chosen overlap formula (B)

```
normalizedWeight(id) = NarrativeKeywordDiscrimination.weight(id) / 6.0
S_overlap = Σ normalizedWeight(id)   for id ∈ Chan(A) ∩ Chan(B)
```

`Chan` = FR-F04 `semanticIds` (keyword ∪ ontology-overlapping symbol tags; each id once).

### Normalized per-id range (rev 1)

| | Raw w | Normalized |
|---|---:|---:|
| Used min (scatter) | 3.348 | **0.558** |
| Used max (df=1) | 5.363 | **0.894** |
| Unused df=0 clamp | 6.0 | 1.0 (never in pairs) |

### Normalized pair distributions

| Slice | n | min | p25 | median | p75 | p90 | p95 | max | ≥1.25 | ≥2.0 | ≥3.5 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| ALL | 2465 | 0.558 | 0.685 | **0.741** | 0.826 | 1.489 | 1.635 | 3.392 | 17.2% | 3.69% | **0%** |
| 1 id | 2016 | 0.558 | 0.685 | 0.711 | 0.778 | 0.826 | 0.894 | **0.894** | 0% | 0% | 0% |
| 2 ids | 353 | 1.128 | 1.374 | 1.463 | 1.537 | 1.635 | 1.720 | 1.788 | 92.9% | 0% | 0% |
| 3+ | 96 | 1.813 | 2.182 | 2.290 | 2.413 | 2.546 | 2.682 | 3.392 | 100% | 94.8% | 0% |
| HF-only | 336 | 0.558 | 0.570 | 0.610 | 0.626 | 0.643 | 1.128 | 1.269 | 0.3% | 0% | 0% |

### §4 objective check

| Objective | Result |
|---|---|
| Single HF cannot admit alone | **PASS** (≤0.643; Standard needs ≥2 families + S≥1.25) |
| Single rare cannot Standard-admit alone | **PASS** (≤0.894) |
| Two specific ≫ one | **PASS** (2-id median 1.463 vs 1-id 0.711) |
| Three stronger, not score-ending | **PASS** (3+ median 2.290; max 3.392 < hard wall for other terms) |
| Position/canonical remain meaningful | **PASS** (+0.30…+0.55 still material vs ~0.6–1.5 overlap) |
| Bands usable | **PASS** (see §15) |

---

## 6 — Family-count rules (LOCKED)

Independent families (for admission `independentFamilyCount`):

| Family | Token | Counts when |
|---|---|---|
| SEMANTIC | A | `S_overlap > 0` from shared `semanticIds` (FR-F04) |
| CONTRAST | B | Hard or contextual contrast pair hit |
| TRANSFORM | D | `effectiveSharedTransforms` non-empty |
| CANONICAL | E | undirected relatedIds hit |
| POSITION | F | authoritative position edge between slots |
| ORIENTATION | G | **never alone** — see §9 |
| QUESTION | H | question bonus > 0 |

**FR-F04:** keyword + ontology symbolTag same id = **one** SEMANTIC contribution.

**Tag-only overlap:** does **not** create a second independent family and does **not** increment SEMANTIC if keyword overlap already present. Tag-only alone does **not** create SEMANTIC family for admission (see §7).

---

## 7 — Tag-only rule (LOCKED)

Catalog tag-only motif ids (not in `NarrativeKeywordIds.all`):

`alchemy`, `breakthrough`, `endurance`, `friction`, `movement`, `recognition`, `subconscious`, `surrender`, `transformation`, `upheaval`

Orientation frequencies (selected): movement=18, endurance=8, friction=4, recognition=4, others=2.

Pair overlaps: **movement:153**, endurance:28, friction:6, recognition=6, others≤1.

**Decision:** tag-only shared motifs contribute **0** to `S_total`.  
They may appear in provenance as `symbolTag` for tie-awareness only.  
They **never** admit alone and **never** increment independent family count.

Rationale: `movement` alone would flood ~153 pairs with noise under even a +0.10 scheme.

---

## 8 — Question relevance rule (LOCKED)

Uses `QuestionKind` only — **no prose NLP**.

| QuestionKind | `S_question` |
|---|---|
| `open` | **0** |
| `guidance` | **0** (profile slice already selects `actionDirection`; no safe small keyword set) |
| `relationship` | **+0.15** iff ≥1 shared semantic id ∈ `QUESTION_RELATIONSHIP_IDS` |
| `decision` | **+0.15** iff ≥1 shared semantic id ∈ `QUESTION_DECISION_IDS` |

```
QUESTION_RELATIONSHIP_IDS = {
  belonging, intimacy, reciprocity, union, attachment, nurture, coldness, isolation
}

QUESTION_DECISION_IDS = {
  choice, direction, indecision, pause, momentum, resistance, clarity
}
```

Rules:

- Never admits alone
- Never invents a relationship without another structured family
- Values are **{0, +0.15} only** (no negative question scoring)

---

## 9 — Orientation family G (LOCKED)

- upright↔reversed **alone** → **0** score, **0** family count  
- same orientation **alone** → **0** score, **0** family count  
- May add provenance `orientationPair` **only when** contrast (B) or effective shared transform (D) already fires  
- No upright-positive / reversed-negative numeric bias

---

## 10 — Semantic kind trigger sets (LOCKED)

### Blockage

```
BLOCKAGE_KEYWORDS = {
  delay, resistance, stagnation, bondage, suppression, closing, rigidity
}
BLOCKAGE_TRANSFORMS = { delay, blockedExpression }
```

Emit `blockage` only if kind precedence reaches it **and**  
(≥1 shared `BLOCKAGE_KEYWORDS` **or** ≥1 shared effective `BLOCKAGE_TRANSFORMS`)  
**and** ≥1 other independent family (never HF/single-keyword alone).

### Softening

```
SOFTENING_KEYWORDS = {
  restraint, compassion, pause, balance, nurture
}
```

Emit `softening` only with supportive **or** pressure **or** contrast family present  
**and** ≥1 shared `SOFTENING_KEYWORDS`.

### Escalation

```
ESCALATION_KEYWORDS = {
  haste, anger, overflow, scatter, impatience
}
ESCALATION_TRANSFORMS = { excess }
```

Emit `escalation` only with ≥1 shared escalation keyword **or** shared `excess` transform  
**and** ≥1 other independent family.  
**HF haste alone MUST NOT emit escalation.**

### Resolution

```
RESOLUTION_KEYWORDS = {
  integration, clarity, balance, renewal, release, opening, reciprocity
}
```

Emit `resolution` only with **supportive** position edge **and** ≥1 shared `RESOLUTION_KEYWORDS`.

### Conflict vs contrast

Contrast condition = HARD contrast **or** (CONTEXTUAL contrast **and** opposition edge).

`RelationshipKind.conflict` iff contrast condition **and** either:

1. opposition edge incident to a position with role ∈ `{challenge, avoid}` (includes sevenCard `obstacle` / `what_to_avoid` via role), **or**
2. HARD contrast **and** pressure edge

Otherwise emit `contrast`.

### Cause–effect

`causeEffect` iff temporal edge **and** SEMANTIC family present.  
Meaning: **structural narrative flow** (“earlier context informs later condition”) — **not** guaranteed literal causation.  
Keep one semantic family + temporal as sufficient (threeCard / celtic temporal chains).

### Support vs reinforcement

After higher-precedence kinds fail:

- `reinforcement` iff ≥2 shared semantic ids with `df < 8` **and** mean **raw** `weight(id) ≥ 4.0`
- else `support` if admitted

---

## 11 — Canonical relation inventory

Consume `OraclyTarotCard.relationshipWithOtherCards.relatedIds` as **undirected** (A lists B **or** B lists A).

| Metric | Count |
|---|---:|
| Directed stored refs | **234** |
| Unique unordered pairs | **173** |
| Mutual pairs | **61** |
| One-way pairs | **112** |
| Invalid ids | **0** |
| Self-relations | **0** |

`+0.55` remains **BALANCED** under normalized overlap (≈0.6–1.5 typical).

No note-prose parsing.

---

## 12 — Position bonus audit

Authoritative 29 edges:

| edgeKind | count | bonus | vs normalized scale |
|---|---:|---:|---|
| temporal | 11 | +0.35 | **BALANCED** |
| pressure | 8 | +0.35 | **BALANCED** |
| opposition | 3 | +0.40 | **BALANCED** |
| supportive | 4 | +0.30 | **BALANCED** |
| mirror | 3 | +0.25 | **BALANCED** |

HF keyword + position alone: e.g. 0.56 + 0.30 = 0.86 → strength ≈ 0.25 (weak); admits under Position-strong (≥1 semantic + edge + S≥1.0) only if S≥1.0 — **0.86 fails**. Need slightly stronger second signal or rarer keyword. **BALANCED** — does not trivially strong-admit HF+edge.

No bonus changes.

Contrast bonuses HARD +0.70 / CONTEXTUAL +0.45: **BALANCED**.  
Transform +0.15 (cap +0.30): **BALANCED**.  
FR caps 0.35 / 0.45: **BALANCED** (see §14).

---

## 13 — FR-F01 / FR-F02 worked calculations

### Critical Chan-identity correction

Production:

- `wands_11↑` keywords = `pentacles_11↑` keywords = `{curiosity, learning, messenger}`
- Full FR-F04 semantic Chans **differ** via symbolTags (`inquiry/awakening` vs `craft/teaching`)
- `swords_11↓` / `swords_12↓` keywords identical `{harshSpeech, haste, notListening}`; tags differ

If FR-F01/F02 required full `semanticIds` equality, the known soft Page/Knight rhymes would **bypass** the guard.

**LOCK:** FR-F01/F02 identity uses **orientation `keywordIds` set equality**.  
Cap still applies to the pair’s `S_overlap` (full Chan intersection).  
Family count from SEMANTIC alone ≤ 1; need another family; final strength ≤ 0.45.

### FR-F01 Pages

| Step | Value |
|---|---:|
| Keyword-normalized overlap | **2.193** |
| After FR cap | **0.35** |
| Identity-only admission | **REJECT** (families≤1; S=0.35 < 1.25) |
| + canonical 0.55 only | S=**0.90** → **REJECT** (canonical admission requires S≥1.0; 0.90 < 1.0) |
| SYNTHETIC valid: +canonical 0.55 + opposition 0.40 | S=**1.30** → admit · strength **≈0.371** ≤ 0.45 |

**3D.1B.2:** Pre-repair docs incorrectly labeled FR-F01+canonical (0.90) as admitted. Thresholds were never changed — only the example was wrong. The 1.30 case is **synthetic contract arithmetic** unless a production reading proves that exact signal combination.

### FR-F02 Swords Page/Knight reversed

| Step | Value |
|---|---:|
| Keyword-normalized overlap | **1.973** |
| After FR cap | **0.35** |
| Identity-only | **REJECT** |
| + supportive 0.30 | S=**0.65** → **REJECT** (position-strong requires S≥1.0) |
| SYNTHETIC valid: +canonical 0.55 + opposition 0.40 | S=**1.30** → admit · strength **≈0.371** ≤ 0.45 |

---

## 14 — Admission scenario matrix (normalized B)

Admission (unchanged thresholds; overlap scale fixed):

- **STANDARD:** families ≥ 2 **and** S_total ≥ 1.25  
- **CANONICAL:** E **and** families ≥ 2 **and** S_total ≥ 1.0  
- **POSITION-STRONG:** F edge **and** ≥1 of {A/B/D} **and** S_total ≥ 1.0  

`strength = clamp(S_total / 3.5, 0, 1)`

| Scenario | Families | S_total | Admit | Strength | Appropriate? |
|---|---|---:|---|---:|---|
| 1 HF only | 1 | ~0.56–0.64 | NO | — | YES |
| 1 rare only | 1 | ~0.66–0.89 | NO | — | YES |
| 1 HF + transform | 2 | ~0.71–0.79 | NO (S<1.25) | — | YES |
| 1 rare + transform | 2 | ~0.81–1.04 | NO | — | YES |
| 1 HF + canonical | 2 | ~1.11–1.19 | YES (canonical ≥1.0) | ~0.32–0.34 | YES weak |
| 1 rare + canonical | 2 | ~1.21–1.44 | YES | ~0.35–0.41 | YES |
| 1 HF + supportive | 2 | ~0.86–0.94 | NO | — | YES |
| 1 rare + supportive | 2 | ~0.96–1.19 | borderline / YES if ≥1.0 | ≤0.34 | YES |
| 2 HF ids | 1 | ~1.13–1.27 | NO alone | — | YES |
| 2 specific ids | 1 | ~1.13–1.79 | NO alone | — | YES |
| HARD contrast only | 1 | 0.70 | NO | — | YES |
| HARD + opposition | 2 | ≥1.10 | YES if ≥1.25 or position-strong path | ~0.31+ | YES |
| CONTEXTUAL only | 1 | 0.45 | NO | — | YES |
| CONTEXTUAL + opposition | 2 | ≥0.85 | needs ≥1.0/1.25 | weak | YES |
| FR-F01 identity only | ≤1 | 0.35 | **REJECT** | — | YES |
| FR-F01 + canonical only | 2 | 0.90 | **REJECT** (0.90 < 1.0) | — | YES |
| FR-F01 + canonical + opposition (SYNTHETIC) | ≥2 | 1.30 | YES | ≈0.371 ≤0.45 | YES |
| FR-F02 identity only | ≤1 | 0.35 | **REJECT** | — | YES |
| FR-F02 + supportive | 2 | 0.65 | **REJECT** (<1.0) | — | YES |
| FR-F02 + canonical + opposition (SYNTHETIC) | ≥2 | 1.30 | YES | ≈0.371 ≤0.45 | YES |

---

## 15 — Strength-band examples

Bands unchanged: weak `<0.40` · moderate `0.40–0.69` · strong `≥0.70`.

| Band | Example | S_total | strength |
|---|---|---:|---:|
| **Weak** | 1 HF + canonical | ~1.11–1.19 | **~0.32–0.34** |
| **Moderate** | 2 specific + supportive | ~1.46+0.30=1.76 | **~0.50** |
| **Moderate** | rare + HARD contrast | ~0.80+0.70=1.50 | **~0.43** |
| **Strong** | 3 specific + HARD + temporal | ~2.29+0.70+0.35=3.34 | **~0.95** |
| **Strong** | 2 specific + HARD + supportive | ~1.46+0.70+0.30=2.46 | **~0.70** |

**3D.1B.2:** Removed incorrect weak example “FR-F01 + canonical → 0.90 / 0.257” — that combination is **not admitted**.

Bands remain usable; not almost-all-strong.

---

## 16 — Theme echo calibration

Existing rule: `S_overlap ≥ 2.0` with ≥1 shared id `df < 8` (non-HF-only).

Under **normalized B**:

- Single id max ≈ **0.894** → **cannot** theme-echo  
- HF-only pairs max ≈ **1.269** → still **cannot** reach 2.0 without multi-id / mixed — and HF-only clause already rejects  
- 3+ shared pairs: **94.8%** have norm ≥ 2.0  

**Keep threshold 2.0.**  
It now means roughly **≥2–3 strong semantic atoms**, not one raw IDF hit.

HF-only theme echo: **MUST REJECT** (unchanged).

---

## 17 — Safety review

Opaque ids `envy|projection|fear|attachment|control|rescue|bondage` remain soft channel members only.

No new accusation kinds. No destiny / cheating / illness / criminality / pregnancy / death labels.

Question bonus cannot invent interpersonal claims.

**SAFETY: PASS**

---

## 18 — Final 3D.1C contract (summary)

```
S_overlap = Σ (weight(id)/6.0) over Chan∩
S_contrast = +0.70 HARD | +0.45 CONTEXTUAL | else 0
S_transform = +0.15 × |effectiveSharedTransforms| capped +0.30
S_canonical = +0.55 if undirected relatedIds
S_position = edge bonus (§12 table) if edge present
S_question = 0 | +0.15 per §8
S_tag_only = 0
S_orientation = 0
FR caps: keywordIds-equal Page/court pairs → S_overlap:=min(S_overlap,0.35); SEMANTIC family ≤1; strength≤0.45
S_total = clamp(sum − contradiction penalties, 0, 3.5)
strength = S_total / 3.5
```

Admission / kind precedence / ordering / provenance: as existing spec except where this calibration explicitly corrects (normalized overlap, FR identity on keywordIds, tag-only=0, question/orientation/kind sets).

**OPEN 3D.1C SCORING DECISIONS: 0**

---

## 19 — Open decisions

**0.**

---

*End of Phase 3D.1B.1 calibration.*
