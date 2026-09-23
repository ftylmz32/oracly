# Narrative Memory + Historical Recurrence — Final Independent Re-Audit (Phase 4E Re-Audit)

**Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Re-audit start SHA:** `32eb74f848cef75ceb0a0f9060c96182145b7ab0`  
**Auditor posture:** Independently recompute from production code + tests + frozen fixtures. Docs alone are not evidence. Passing suites alone are not evidence.

**Production files were not modified during this re-audit.**

---

## Provenance (historical)

| Milestone | SHA / status |
|---|---|
| Original Phase 4E audit | Start `40182d17…` · **FAIL** · MAJOR H7 · documented in `NARRATIVE_MEMORY_RECURRENCE_FINAL_AUDIT.md` (preserved) |
| Phase 4E.1 H7 remediation | `6acb2b18…` — transitive union-find component collapse |
| Phase 4E.1a H19 hardening | `32eb74f8…` — exact-tie deterministic ordering |
| This re-audit | Starts at `32eb74f8…` |

The original FAIL document remains the historical record. This file is the freeze-gate re-audit.

---

## Independent methodology

1. Re-read eligibility, order/tie-key, enricher, engines, adapters, validation without trusting prior PASS claims.
2. Confirm Phase 3 scorer/selector/builder/profiles untouched since Phase 4E era (`git log 40182d17..32eb74f8` empty for evidence/data profiles).
3. Re-run H7 / 4E.1 / 4E.1a red-teams and independently inspect H7 union-find + H19 tie-key source.
4. Recompute frozen corpus metrics from fixture JSON (55 rows · 44/44 required classes · langs/kinds).
5. Grep live enricher call sites under `lib/` (must be defining file only).
6. Run mandatory regression suites + analyze + full Flutter.
7. Freeze only if BLOCKER=0 · MAJOR=0 · H1–H19 = 19/19 · live V2 unwired.

---

## Evidence inventory

| Area | Primary sources |
|---|---|
| Spec | `NARRATIVE_MEMORY_RECURRENCE_SPEC.md` (H1–H19) |
| Eligibility | `tarot_historical_eligibility.dart` · `tarot_historical_eligibility_order.dart` |
| Enricher | `tarot_narrative_request_enricher.dart` · validation |
| Engines | card / theme / memory + relevance |
| Adapters | history source · connected memory · live source index · snapshot · deletion |
| Corpus | `tarot_narrative_history_enrichment_v1.json` (55 scenarios) |
| Remediation proofs | `tarot_4e_h7_*` · `tarot_4e1_*` · `tarot_4e1a_*` red-teams |
| Original FAIL | `NARRATIVE_MEMORY_RECURRENCE_FINAL_AUDIT.md` |

---

## H1–H19 matrix

| ID | Result | Evidence summary |
|---|---|---|
| H1 | PASS | Unknown orientation sentinel; sample path preserves `orientationKnown` |
| H2 | PASS | Explicit `topicId` on historical record |
| H3 | PASS | Future + >90d excluded; no `abs` |
| H4 | PASS | Distinct physical prior readings; per-reading card dedupe |
| H5 | PASS | Additive memory metadata deferred (not in 4A surface) |
| H6 | PASS | Generic topics never authorize `topic_match` |
| H7 | PASS | Transitive alias component collapse (union-find); pairwise `samePhysicalIdentity` unchanged |
| H8 | PASS | `aşk` alias; ASCII `ask` excluded |
| H9 | PASS | `omitReason` contracts including `privacy` / `included` |
| H10 | PASS | Typed theme support refs |
| H11 | PASS | Support refs capped by listed max |
| H12 | PASS | Free-text ≥2 meaningful tokens |
| H13 | PASS | Connected-memory `(sourceType, sourceId)` dedupe |
| H14 | PASS | Live Tarot ids from accepted adapter rows only |
| H15 | PASS | Typed `removeBySourceAndType` |
| H16 | PASS | Shared session→ReadingModel fallback for kind/intention/topic |
| H17 | PASS | Live aliases = session.id + linked ReadingModel.id only |
| H18 | PASS | `currentOwnerId` + `privacyBlocked` required; no default; short-circuit |
| H19 | PASS | Exact primary-order ties: sessionId ASC + canonical payload key (no ownerId/hash/clock) |

**19 / 19 PASS**

---

## Findings by section (A–Q)

### A — Phase 3 freeze · **PASS**

- No commits to scorer / selector / builder / profiles / ontology between `40182d17` and `32eb74f8`.
- Enricher copies Phase 3 identity fields (`question`, `spread`, `cards`, `relationships`) unchanged; only Phase 4 fields rewritten.
- No current-spread relationship rescoring.

### B — Architecture / purity · **PASS**

- `NarrativeEvidenceBuilder` remains pure/sync/storage-free (Phase 3 freeze).
- `TarotNarrativeRequestEnricher` pure sync; engine order **card → theme → memory**.
- No AI / network / persistence in pure enrichment path.
- No `DateTime.now()` under `lib/.../narrative/history/`; clock injected as `now`.

### C — Owner / privacy · **PASS**

- Same-owner only when `currentOwnerId != null`; owner-bound excludes ownerless; anonymous includes null-owner only.
- `privacyBlocked=true` short-circuits engines; yields empty recurrence/themes; `omitReason=privacy`; `priorReadingCount=0`; hint lists `[]`.
- Owner never inferred from history for enrichment args (H18).

### D — Source existence · **PASS**

- H14 / H15 / H17 red-teams green; typed deletion; `linked.sessionId` not independent authority.
- Same raw `sourceId` across feature types remains type-safe.

### E — Delete / clear / restart · **PASS**

- Storage→enricher shadow: Tarot delete removes recurrence; coffee wipe typed; restart preserves absence; clear paths covered by privacy/history suites.

### F — H7 physical identity · **PASS**

Independently inspected production:

1. Filter (struct/owner/current/time) **before** union.
2. Sort via H19 comparator.
3. Union-find over shared alias tokens (`readingId` / `sessionId`).
4. Keep first row per root (already newest-first).
5. Then `maxPriorReadingsScanned`.

Red-team: A↔B↔C · all permutations · bridge-newest · 5+ chain · disconnected · direct dupes · max-20 after collapse · no field merge · foreign/current/out-of-window/future bridges rejected.

`samePhysicalIdentity` remains **pairwise** (A↛C may be false while component collapse is transitive).

**Original MAJOR H7: CLOSED.**

### G — H19 exact-tie determinism · **PASS**

`compareHistoricalNewestFirst` / `_canonicalTieKey`:

- Primary: `occurredAt` UTC DESC · `readingId` ASC (**unchanged**).
- Ties: normalized `sessionId` ASC · then deterministic payload (`spreadId`, `questionKind.name`, `topicId`, `intentionSummary`, `interpretationSummary`, ordered card fields).
- Tie-key contains **no** `ownerId`, `hashCode`, object identity, random, or clock.

Red-team permutations: session / spread / card / text / identical duplicates · downstream prior counts, recurring cards, occurrenceCount, evidence IDs stable.

**H19 exact-tie order sensitivity: CLOSED.**

### H — Card recurrence · **PASS**

Candidates ⊆ current cards; current excluded; distinct physical priors; per-reading once; samples max 5; missing `positionKey` may count without fabricating sample; ranking + `rec_card_##` deterministic.

### I — Context overlap · **PASS**

Topic / kind-token / keyword-map positives; negatives for same-card-alone, same-spread-alone, generic topics, stopwords, ASCII `ask`; TR/EN/RU recall scenarios present.

### J — Theme recurrence · **PASS**

OraclyMemory authority; ≥2 distinct source types; threshold ≥0.35; max 4 themes; support refs capped; current-spread `themeRepetition` cannot masquerade as historical.

### K — Memory evidence · **PASS**

Max 4 entries · ≤220 · ≤800 total · hint lists always `[]` · `priorReadingCount` from eligible physical scan · omitReason set · free-text ≥2 tokens · explicit recall cannot bypass firewalls · epistemic framing preserved.

### L — Referential integrity · **PASS**

Namespaces `rel_##` / `mem_##` / `rec_card_##` / `rec_theme_##`; enrichment validation exit contract; closed-universe checks.

### M — Frozen corpus · **PASS**

| Metric | Value |
|---|---|
| Actual scenarios | **55** |
| Fixture `scenarioCount` metadata | **52** (stale — INFO only; not altered) |
| Required classes | **44 / 44** present |
| Extra class tags | `contextsOverlap_true` / `contextsOverlap_false` |
| Languages | EN **25** · TR **18** · RU **12** |
| Question kinds | open **17** · relationship **21** · decision **10** · guidance **7** |
| `privacyBlocked=true` rows | **3** |
| Expected recurringCards non-empty | **26** |
| Expected recurringThemes non-empty | **8** |

Every scenario matches frozen expected via corpus suite. No runtime expectation generation.

### N — Storage → enricher shadow · **PASS**

Owner match / mismatch / delete / restart / typed collision covered by shadow + privacy red-teams.

### O — Live-path firewall · **PASS**

- `TarotNarrativeRequestEnricher` production importers outside defining history file: **0**
- Live Narrative V2 user path: **NOT WIRED**
- `release/ios-1.0` tip remains `1b7151dca954f0cc25f39f815c0dacf0613a1164` (Build 4)
- No merge performed in this re-audit

### P — Security / bounds · **PASS**

`RequestBounds.defaults` = **20 / 5 / 12 / 800 / 4**. No owner id on request/evidence output models. No recurrence cache. No new persistence. No AI/network in pure path.

### Q — Original Phase 4E finding closure · **PASS**

| Finding | Status |
|---|---|
| Original MAJOR H7 | **CLOSED** |
| H7 order sensitivity | **CLOSED** |
| H19 exact-tie order sensitivity | **CLOSED** |

---

## Severity counts

| Severity | Count | Item |
|---|---|---|
| **BLOCKER** | **0** | — |
| **MAJOR** | **0** | — |
| **MINOR** | **2** | Explicit-recall relevance floor observations (theme + memory) — **by design**, non-blocking (carried from original 4E) |
| **INFO** | **3** | Shadow-only enricher · fixture `scenarioCount: 52` vs actual **55** · EN stopwords rely partly on length≥4 |

---

## Test results (re-audit run)

| Suite | Result |
|---|---|
| H7 / 4E.1 / 4E.1a red-team | **18 passed / 0 failed** |
| Narrative History | **146 passed / 0 failed** |
| Privacy | **33 passed / 0 failed** |
| Narrative Evidence | **176 passed / 0 failed** |
| Profile Domain | **114 passed / 0 failed** |
| Phase 2/2.1 narrative_v2 | **27 passed / 0 failed** |
| R2/R2.1 | **13 passed / 0 failed** |
| Analyze | **0 errors / 0 warnings** (198 pre-existing infos) |
| Full Flutter | *(recorded at commit time)* |

---

## Freeze determination

**BLOCKER = 0 · MAJOR = 0 · H1–H19 = 19/19 PASS · live V2 unwired · suites green.**

### Phase 4 Memory + Historical Recurrence: **FROZEN**

**Phase 4E Re-Audit: PASS**

Explicitly retained:

- Live Narrative V2 = **NOT WIRED**
- Runtime Narrative Tarot Engine = **NOT USER-REACHABLE**
- This freeze does **not** claim App Store / release readiness.

Do **not** start live Narrative V2 wiring without a separate approved phase.

---

## Audit artifacts

- This document: `docs/product/tarot/NARRATIVE_MEMORY_RECURRENCE_FINAL_REAUDIT.md`
- Historical FAIL: `docs/product/tarot/NARRATIVE_MEMORY_RECURRENCE_FINAL_AUDIT.md` (unchanged as FAIL record)
- Remediation red-teams under `test/features/tarot/narrative_history/red_team/`
