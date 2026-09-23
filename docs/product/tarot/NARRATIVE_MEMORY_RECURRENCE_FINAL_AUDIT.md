# Narrative Memory + Historical Recurrence — Final Independent Audit (Phase 4E)

**Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Audit start SHA:** `40182d177ca3bb895438218f672db06e9fcf88fe`  
**Auditor posture:** Independently recompute from production code + tests + frozen fixtures. Docs alone are not evidence. Passing suites alone are not evidence.

---

## Independent methodology

1. Read production history engines, adapters, enricher, and eligibility without trusting handoff PASS claims.
2. Cross-check H1–H18 against concrete implementations.
3. Red-team H7 with a non-transitive physical-identity chain (A↔B, B↔C, A↛C).
4. Spot-check frozen corpus scenarios against history/expected (not class labels alone).
5. Confirm live-path firewall by repo grep.
6. Run targeted suites + full Flutter; leave failing audit evidence on MAJOR.

**Production files were not modified during this audit.**

---

## Evidence inventory

| Area | Primary sources |
|---|---|
| Spec | `docs/product/tarot/NARRATIVE_MEMORY_RECURRENCE_SPEC.md` (H1–H18) |
| Enricher | `tarot_narrative_request_enricher.dart`, `tarot_narrative_enrichment_validation.dart` |
| Eligibility | `tarot_historical_eligibility.dart` |
| Engines | card / theme / memory recurrence + relevance |
| Adapters | history source, connected memory, live source index, snapshot loader, deletion |
| Corpus | `test/fixtures/tarot_narrative_history_enrichment_v1.json` (55 scenarios) |
| Audit proof | `test/.../red_team/tarot_4e_h7_chained_alias_red_team_test.dart` |

---

## Findings by section

### A — Architecture / Phase 3 freeze · **PASS**

- Enricher mutates only `memory` / `recurringCards` / `recurringThemes`; Phase 3 fields passed by identity.
- Enricher + builder: pure sync; no storage / AI / network / `DateTime.now()` in enricher.
- `TarotNarrativeRequestEnricher` has **0** production call sites outside its defining file (shadow).
- Live Narrative V2 remains unwired.

### B — Owner / privacy · **PASS**

- Owner-bound / ownerless rules in `TarotHistoricalEligibility._ownerOk`.
- Loader sets `privacyBlocked` on owner-boundary mismatch.
- H18: `required bool privacyBlocked` — **no default**; engines not invoked when true.
- Privacy output: empty recurrence/themes; `omitReason=privacy`; `priorReadingCount=0`; hints `[]`.
- Owner id never written onto request / evidence models.

### C — Source existence / ghost · **PASS**

- H14: live Tarot ids from accepted adapter rows only.
- H15: typed `removeBySourceAndType`.
- H17: live aliases = `session.id` + linked `ReadingModel.id` only; `linked.sessionId` not an authority.
- Delete / clear / restart shadow suites cover recurrence and memory/theme removal.

### D — Eligibility / physical identity · **FAIL (MAJOR)**

Lookback, future exclude, current exclude, sort, and max-20 bound match §7.

**H7 MAJOR — non-transitive alias chain double-count**

`samePhysicalIdentity` is pairwise and **not transitive**. `_dedupePhysicalIdentity` is greedy newest-first against the *kept* set only. When bridge row B is dropped, ends A and C can both survive.

Concrete chain (proven by audit test):

| Row | readingId | sessionId | time |
|---|---|---|---|
| A | `ra` | `sab` | newest |
| B | `rb` | `sab` | mid |
| C | `rb` | `sbc` | oldest |

- A↔B match (session) · B↔C match (readingId) · A↔C **no** match  
- Greedy keep: A kept → B dropped → **C kept** → eligible length **2**  
- Spec H7 requires one physical reading → length **1**

Audit test actual: `Expected: <1> Actual: <2>` got `[ra, rb]`.

When B is newest, length correctly collapses to 1 — proving **order-dependent** incorrectness.

**Impact:** Inflates `eligiblePriorReadingCount`, card `occurrenceCount`, and any downstream bound that trusts “distinct physical readings.”

### E — Card recurrence · **PASS** (subject to H7 input)

Engine logic for pick-once, sample skip without positionKey, ranking, and `rec_card_##` matches spec when eligibility is correct. H7 defect can still inflate counts upstream.

### F — Context overlap · **PASS**

Three paths with precedence; generic topics / stopwords / ASCII `ask` excluded; same card/spread alone insufficient.

### G — Theme recurrence · **PASS**

≥2 distinct source types; Tarot-only rejected; typed support refs; max 4 / max 5; threshold 0.35; current-spread `themeRepetition` never alone.

**MINOR (by design):** Explicit recall alone can raise relevance to 0.50 (≥0.35).

### H — Memory evidence · **PASS**

Bounds 4 / 220 / 800; hints always `[]`; omitReason contracts; ≥2-token free-text; ranking formula; recall does not bypass eligibility.

**MINOR (by design):** Explicit recall alone can admit otherwise weak memories (spec-allowed).

### I — Enricher / referential integrity · **PASS**

Order card → theme → memory; privacy short-circuit; idempotence / revocation tests; validation A–N present.

### J — Frozen corpus · **PASS** (with INFO)

- 55 scenarios · 44/44 required classes tagged · real Phase 3 bases  
- TR 18 / EN 25 / RU 12 · open 17 / guidance 7 / relationship 21 / decision 10  
- Epistemics: interpretation / observation / fact / preference all present  
- No owner tokens in expected blobs · no runtime expected=actual writer  
- **INFO:** fixture header `scenarioCount: 52` stale vs 55 rows

### K — Storage→enrichment shadow · **PASS**

Owner match, privacyBlocked, delete recurrence, delete coffee theme/memory, restart no-ghost covered by shadow suite.

### L — Live path firewall · **PASS**

Enricher importers outside history defining file in `lib/`: **0**. Release/ios-1.0 / Build 4 untouched.

### M — Bounds / security · **PASS**

`RequestBounds.defaults` = 20 / 5 / 12 / 800 / 4. No new persistence / network / AI in Phase 4 engines. No owner id in enricher output.

---

## Corpus recomputation (summary)

| Metric | Value |
|---|---|
| Scenarios | 55 |
| Required classes | 44/44 |
| TR / EN / RU | 18 / 25 / 12 |
| open / guidance / relationship / decision | 17 / 7 / 21 / 10 |
| Privacy scenarios | ≥3 |
| Recurring-card scenarios | ≥10 |
| Theme scenarios | ≥8 |
| Memory-included scenarios | ≥10 |

---

## Test results (audit run)

| Suite | Result |
|---|---|
| H7 chained-alias audit test | **1 failed** (MAJOR proof) · 1 passed |
| Narrative History | **129 passed / 1 failed** (H7 proof) |
| Privacy | **14 passed / 0 failed** |
| Narrative Evidence | **176 passed / 0 failed** |
| Profile Domain | **114 passed / 0 failed** |
| Phase 2/2.1 narrative_v2 | **27 passed / 0 failed** |
| R2/R2.1 | **13 passed / 0 failed** |
| Analyze (`lib/.../history/`) | **0 issues** |
| Full Flutter | **4075 passed / 1 failed / 15 skipped** |

---

## Severity counts

| Severity | Count | Item |
|---|---|---|
| **BLOCKER** | **0** | — |
| **MAJOR** | **1** | H7 non-transitive physical-identity dedupe double-count |
| **MINOR** | **2** | Explicit-recall relevance floor (theme + memory; by design) |
| **INFO** | **3** | Shadow-only enricher; fixture `scenarioCount` stale; EN stopwords rely partly on length≥4 |

---

## H1–H18 scorecard

| ID | Result |
|---|---|
| H1–H6 | PASS |
| **H7** | **FAIL** |
| H8–H18 | PASS |

**17 / 18 PASS**

---

## Final answer

**Is Phase 4 Memory + Historical Recurrence safe, deterministic, privacy-preserving, source-grounded, and complete enough to freeze and move to later user-path review?**

### **NO**

Reason: **MAJOR** H7 physical-identity dedupe can retain multiple eligible rows for one chained alias physical reading, violating “distinct prior physical readings” and making eligibility order-sensitive.

**Phase 4 is NOT FROZEN.**

**Do not start live Narrative V2 wiring.** Next required work: remediate H7 transitive/component physical-identity collapse (production fix outside this audit), then re-run Phase 4E.

---

## Audit artifacts

- `test/features/tarot/narrative_history/red_team/tarot_4e_h7_chained_alias_red_team_test.dart` — failing contract proof (kept intentionally)
- This document

---

## Phase 4E.1 remediation note (appended — does not rewrite the FAIL)

**Date:** 2026-09-23  
**Start SHA:** `1eb09c2cb343a1d58937aeccff05a35c0b3e2541`

H7 remediation implemented in Phase **4E.1**:

- `TarotHistoricalEligibility._dedupePhysicalIdentity` now collapses **transitive** alias connected components via union-find over shared identity tokens (`readingId` / `sessionId` in one namespace).
- `samePhysicalIdentity` pairwise semantics **unchanged** (A↛C may remain false).
- Representative = newest row per component after the existing eligibility sort; **no field merge**.
- Component construction uses only post-filter rows (rejected owner/current/time bridges cannot join components).

The original Phase 4E FAIL above remains the historical audit record.

**Phase 4 remains NOT FROZEN** until an independent Phase 4E **re-audit** PASSes.
