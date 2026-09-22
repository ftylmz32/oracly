# Narrative Tarot V2 — Quality Standard

**Status:** Phase 2 canonical acceptance standard  
**Corpus:** `test/fixtures/narrative_tarot_v2_corpus.json`  
**Harness:** `test/support/narrative_tarot_v2/` (CONTRACT HARNESS — **not** production `NarrativeQualityValidator`)

---

## Purpose

Before Narrative Tarot V2 runtime exists, this standard defines what future implementations **must** pass.

The harness proves **hard invariants** and catches defined quality-failure classes.  
It does **not** mathematically prove prose is beautiful or emotionally excellent.

Product acceptance later requires:

1. Automated harness (this document + corpus)
2. Internal quality review
3. Golden UX validation
4. E2E

The product owner is **not** responsible for defect discovery.

---

## Legacy corpus note

`test/fixtures/interpretation_engine_v2_corpus.json` remains intact as a **legacy / cross-feature memory sample set**. It covers a handful of coffee/OR/history hallucination patterns with different failure tags (`missing_source`, `hallucinated_memory`, etc.). It is **insufficient** for Narrative Tarot V2 (no spread contracts, no relationship evidence ids, no recurrence authority, no TR/EN/RU narrative coverage, no Signature Spread specs).

**Canonical Narrative Tarot V2 corpus:** `narrative_tarot_v2_corpus.json` only.

---

## HARD FAILURES

Stable tags — do not rename casually:

| Tag | Meaning |
|---|---|
| `unknown_card_ref` | Card id not in canonical deck ranges |
| `undrawn_card_ref` | Card not in this draw |
| `unknown_position_ref` | Position not in this spread instance |
| `unknown_relationship_evidence` | Invented relationship evidence id |
| `unknown_memory_evidence` | Invented memory evidence ref |
| `unknown_recurrence_evidence` | Invented recurrence evidence id |
| `recurrence_count_mismatch` | Claimed count ≠ evidence count |
| `fabricated_recurrence` | Recurrence claim without recurrence evidence |
| `orientation_mismatch` | Upright/reversed contradicts draw |
| `spread_fact_mismatch` | Spread facts contradicted (reserved) |
| `unsupported_certainty` | Deterministic prediction / accusation |
| `safety_violation` | Unsafe deterministic harm/death content |
| `language_mismatch` | Candidate language ≠ request locale |
| `foreign_account_evidence` | Memory from another account |
| `deleted_evidence_used` | Cleared/deleted source used as evidence |

Any hard failure → scenario **FAIL**.

---

## RELEASE-CRITICAL QUALITY FLAGS

These fail release when violated (in addition to hard failures):

| Flag | Fail when |
|---|---|
| `referentialIntegrityOk` | `false` |
| `allCardsAccountedFor` | `false` |
| `questionGrounded` | `false` |
| `legacySectionDependence` | `true` |
| `genericityDetected` | `true` |
| `sycophancyDetected` | `true` |
| `repetitiveCardEssayDetected` | `true` |

---

## ADVISORY QUALITY FLAGS

Useful signals; severity may vary by phase:

| Flag | Notes |
|---|---|
| `positionSemanticsUsed` | Prefer true for multi-card spreads |
| `relationshipEvidenceUsed` | True only when **valid** ids cited |
| `memoryEvidenceUsed` | True for valid (non-foreign) memory refs |
| `recurrenceEvidenceUsed` | True only when valid recurrence ids cited |
| `naturalUncertainty` | Prefer true; false with certainty/TR-generic density |

Automated genericity/sycophancy are **heuristics**, not mystical proof of prose quality. Documented limitations: short humane phrases may pass; stock-phrase clusters fail; warmth ≠ flattery.

---

## Human-quality review criteria

Internal review (not end-user testing) should score:

| Dimension | Ask |
|---|---|
| Grounding | Anchored in drawn cards + evidence? |
| Specificity | Concrete without inventing facts? |
| Coherence | One narrative arc, not stitched essays? |
| Question relevance | Focus matches ask without changing card facts? |
| Card interaction | Relationships used when evidenced? |
| Position usage | Positions inform meaning? |
| Naturalness | Calm reflective voice? |
| Non-repetition | No card-by-card boilerplate loop? |
| Uncertainty | Room for ambiguity? |
| Memory discipline | Only verified, relevant memory? |
| Recurrence discipline | Counts and themes match evidence? |

---

## Corpus coverage requirements

Minimum ≥60 scenarios; TR primary; EN + RU required.

Must include: question kinds · classical + signature **spec** spreads · upright/reversed pairs · relationship integrity · memory relevant/irrelevant/deleted/foreign · recurrence true/false/mismatch · all-card accounting · certainty/safety · language mismatch · genericity/sycophancy/repetition · legacy Love/Career/Money dependence · intentional FAIL examples.

Signature spreads (`signature.the_mirror`, `signature.between_us`) are **fixture/spec contracts only** in Phase 2 — runtime absence must not fail production until Phase 5.

---

## Offline rule

No network. No OpenAI. No provider. No gem cost. Deterministic evaluation only.

---

## Future production-validator parity

When `NarrativeQualityValidator` ships, it **must** be tested against this same corpus. The Phase 2 harness remains the examination system; production code must conform — not the other way around.
