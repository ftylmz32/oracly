# NARRATIVE PROVIDER SHADOW QA — Phase 6E.4 (Manifest V2 / Result Contract V2)

**Status:** EXECUTION COMPLETE — **TRANSPORT FAIL** on all 6 calls (no structured prose captured)
**Date:** 2026-09-24
**QA RUN HEAD:** `6e2fa96ab1ca0bfc48f2ac7a84a3a6557a7dee92`
**Branch:** `fix/final-product-remediation-20260922`
**Manifest:** `test/fixtures/tarot_narrative_provider_shadow_manifest_v2.json` (version 2, 6 entries)
**Result contract target:** **2** · schema `oracly_tarot_narrative_v2`
**Request contract:** mode=`narrative_v2` · contractVersion=**1** (unchanged)
**Authorized call cap:** 6
**Real provider calls used:** 6
**Remaining:** 0
**Call cap exceeded:** NO
**Auto retries:** 0
**Same HEAD for all calls:** YES
**Billing / gems / wallet:** untouched
**History / journal / cache / memory writes:** 0
**Production code modified during run:** NO
**Live Narrative V2 wired:** NO
**6F implemented:** NO
**Crossroads called:** NO

> Agent does **not** claim provider writing quality is production-ready.
> Agent does **not** self-certify production writing quality.
> This run produced **zero** backend-valid structured Narrative results; ChatGPT cannot review prose that was never returned.
> Next remediation (separate phase) must fix provider transport / schema acceptance before any new Manifest V2 authorization.

---

## Call ledger

| # | Manifest ID | Transport | Backend structured | Backend quality rejection | Client parse | Narrative evidence | AiOutputQuality | Latency ms | Provider request id |
|---|-------------|-----------|--------------------|---------------------------|--------------|--------------------|-----------------|------------|---------------------|
| 1 | `psm_v2_01_single_open_en` | failure | FAIL | — | FAIL | FAIL | FAIL | 1738 | `req_8e4d705682aa428f97a3ddddd3cb9f50` |
| 2 | `psm_v2_02_single_guidance_tr_reversed` | failure | FAIL | — | FAIL | FAIL | FAIL | 974 | `req_8f5ade409f83492d80070070d20af16f` |
| 3 | `psm_v2_03_single_relationship_ru` | failure | FAIL | — | FAIL | FAIL | FAIL | 537 | `req_c8d83c617c184228b5a42319db2b2ab6` |
| 4 | `psm_v2_04_three_contrast_en` | failure | FAIL | — | FAIL | FAIL | FAIL | 1001 | `req_f6f38c5d8e744d1d93307db150a9873b` |
| 5 | `psm_v2_05_five_conflict_ru` | failure | FAIL | — | FAIL | FAIL | FAIL | 246 | `req_16a4bf7500cc4780a775affbb762bae9` |
| 6 | `psm_v2_06_enriched_multi_memory_en` | failure | FAIL | — | FAIL | FAIL | FAIL | 259 | `req_1795605f688a4eb58c076d22a2797578` |

Exact provider request ids: see `test/fixtures/tarot_narrative_provider_shadow_results_6e4_v2.json`.

## Coverage matrix (intent — not delivered prose)

| Dimension | Cases |
|-----------|-------|
| EN | psm_v2_01, psm_v2_04, psm_v2_06 |
| TR | psm_v2_02 |
| RU | psm_v2_03, psm_v2_05 |
| single | psm_v2_01, psm_v2_02, psm_v2_03, psm_v2_06 |
| threeCard | psm_v2_04 |
| fiveCard | psm_v2_05 |
| reversed | psm_v2_02, psm_v2_03 (+ corpus cards in 04/05) |
| relationship evidence | psm_v2_04 (contrast), psm_v2_05 (conflict) |
| no-relationship | psm_v2_01, psm_v2_02, psm_v2_03, psm_v2_06 |
| future-position Q1 | psm_v2_04 |
| enriched multi-memory Q2 | psm_v2_06 (`enrichedProviderQaRequest`, displayName=The Fool, memory=2) |

## Precall validation

**PASS** — all 6 candidates validated offline before call #1:

- Manifest V2 references resolve
- Deterministic request build (corpus / `enrichedProviderQaRequest`)
- 6C serializer + 6D wire dump
- Backend `validateNarrativeTarotPayload`
- Result Contract target = 2 · schema name `oracly_tarot_narrative_v2`
- No private identity keys in outbound wire
- Languages / spreads / card counts / displayNames exact
- Enriched case: authoritative displayName ≠ `major_00`, memory≥2, recurrence present, classical.single current spread
- No Crossroads as current spread

Real provider calls started only after PASS.

## Aggregate gates

- Transport successes: **0**
- Backend structured passes: **0**
- Backend quality rejections (deterministicFuture etc.): **0** (never reached parse)
- Client parser passes: **0**
- Narrative evidence quality passes: **0**
- AiOutputQuality passes: **0**
- Internal id leaks in structured prose: **n/a** (no structured prose)
- Deterministic-future rejections: **0**
- Unsupported relationship / fake recurrence / fake memory: **n/a**

## Transport failure observation (for remediation — not fixed in this run)

All six calls returned `ProxyError` / `provider_error` after HTTP round-trips (provider request ids present).

**Likely cause (hypothesis, not remediated here):** Result Contract V2 OpenAI JSON Schema includes `uniqueItems: true` on `memoryInsights[].memoryIndices`. OpenAI Structured Outputs strict schema subset historically rejects `uniqueItems`, which would fail the request before any model prose is generated. V1 schema (integer `memoryIndex`) did not use that keyword and completed successfully in 6E.2.

**Per Phase 6E.4 rules:** once call #1 began, production prompt/schema/validator were **not** modified. Cap exhausted (**0 remaining**). No retry.

## Q1–Q5 review status

| Issue | Status this run |
|-------|-----------------|
| Q1 future certainty | **NOT OBSERVABLE** — no Call #4 prose |
| Q2 memoryIndices provenance | **NOT OBSERVABLE** — no Call #6 prose |
| Q3 section repetition | **NOT OBSERVABLE** |
| Q4 relationship epistemic | **NOT OBSERVABLE** |
| Q5 TR/RU naturalness | **NOT OBSERVABLE** |

## Enriched case request facts (precall — for next run)

- Harness: `enrichedProviderQaRequest`
- Display name: **The Fool** (authoritative)
- Memory entry count: **2**
- Memory 0: `[INTERPRETATION][coffee] shared loyalty partner reflection coffee`
- Memory 1: `[INTERPRETATION][dream] shared loyalty partner reflection dream`
- Recurrence: present on request
- Question: decision / love (“Should I stay in this relationship?”)
- Current spread: `classical.single`

## Per-case structured results

### CALL #1 — `psm_v2_01_single_open_en`

- Language: `en` · Spread: `classical.single` · cards: 1 · display: The Fool
- Transport: **failure** · typedFailure: `{ type: ProxyError, code: provider_error, message: provider_error }`
- Structured result: **null** (not fabricated)

### CALL #2 — `psm_v2_02_single_guidance_tr_reversed`

- Language: `tr` · Spread: `classical.single` · cards: 1 · display: Kupa Beşlisi
- Transport: **failure** · same typedFailure shape
- Structured result: **null**

### CALL #3 — `psm_v2_03_single_relationship_ru`

- Language: `ru` · Spread: `classical.single` · cards: 1 · display: Девятка Мечей
- Question: `Как развиваются наши отношения?`
- Transport: **failure** · Structured result: **null**
- MIND-READING CLAIM FOUND: **n/a**
- OBJECTIVE RELATIONSHIP CLAIM FOUND: **n/a**

### CALL #4 — `psm_v2_04_three_contrast_en`

- Language: `en` · Spread: `classical.threeCard` · cards: 3 · future-position case
- Transport: **failure** · Structured result: **null**
- Deterministic-future audit: **n/a** (no prose)

### CALL #5 — `psm_v2_05_five_conflict_ru`

- Language: `ru` · Spread: `classical.fiveCard` · cards: 5
- Transport: **failure** · Structured result: **null**

### CALL #6 — `psm_v2_06_enriched_multi_memory_en`

- Language: `en` · Spread: `classical.single` · cards: 1 · memory entries: 2
- Transport: **failure** · Structured result: **null**
- MemoryIndices audit: **n/a**

## Safety

- Secrets in artifacts: scanned for `sk-`, `Bearer`, private-key PEM markers — **NONE** in QA fixture / this doc
- API keys / auth headers: **not captured**

## Historical firewall

- 6E.2 QA doc / payloads / results / Manifest V1: **unchanged**
- Manifest V2: **unchanged** during and after calls

## Agent quality claim

**PROVIDER QUALITY CLAIMED PASS BY AGENT: NO**

This document is evidence of a controlled six-call attempt under Result Contract V2. Independent ChatGPT review of **writing quality** cannot proceed until a later authorized run returns backend-valid structured prose.
