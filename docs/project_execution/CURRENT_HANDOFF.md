# CURRENT HANDOFF

**Living state — factual only**
**Updated:** 2026-09-22 — Tarot Phase 2.1 harness false-positive hardening

---

## How to read SHAs in this document

Do **not** treat this file as a live pointer to the branch tip.

| Concept | Value | Meaning |
|---|---|---|
| Canonical branch | `fix/final-product-remediation-20260922` | Active remediation branch |
| Active worktree | `D:/oracly_final_r1` | Where remediation docs/code land |
| Last verified **application/code** baseline | `173d75228248baf32ea0d4f04fe936665efff342` | R2.1 — last Flutter-verified code tip (3627/0/15/0) |
| Phase 0 documentation baseline | `7155ad8535bd051a152437757fd11296b243de0b` | Night Shift docs tip at Phase 1 task start |
| Phase 1.1 task start baseline | `f506c7733822f24d57a2e14254004c907a789f33` | Start of contract hardening |
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
`design/runtime/astrology_runtime.png`, generated plugin registrants, possible line-ending dirt on tests, `tool/qa/`.

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
| Runtime Narrative Tarot Engine | **NOT IMPLEMENTED** |
| Tarot Visual System (locked goldens) | **NOT IMPLEMENTED** |
| Phase 2 — Quality corpus + harness | **COMPLETE** |
| Phase 2.1 — Harness false-positive hardening | **COMPLETE** |
| Phase 3 — Semantic profiles + Narrative Evidence Engine | **NOT STARTED** |

### Spec artifacts

- `docs/product/tarot/NARRATIVE_TAROT_SPEC.md`
- `docs/product/tarot/NARRATIVE_TAROT_DATA_CONTRACT.md`
- `docs/product/tarot/NARRATIVE_TAROT_MIGRATION_PLAN.md`
- `docs/product/tarot/NARRATIVE_TAROT_QUALITY_STANDARD.md`

### Phase 2 artifacts

- Canonical corpus: `test/fixtures/narrative_tarot_v2_corpus.json`
- CONTRACT HARNESS (test-only): `test/support/narrative_tarot_v2/`
- Tests: `test/features/tarot/narrative_v2/`
- Legacy corpus retained: `test/fixtures/interpretation_engine_v2_corpus.json` (insufficient for V2; not deleted)

**Runtime Narrative Tarot:** NOT IMPLEMENTED
**Phase 3:** NOT STARTED

---

## Latest verified baselines

| Suite | Result |
|---|---|
| Flutter (at code baseline `173d7522`) | **3627** passed · **0** failed · **15** skipped · **0** timed out |
| Backend (known) | **658** passed · **0** failed · **1** skipped |

---

## Open canonical backlog (NOT completed)

### P1

- Yildizname / Birth Chart: time/place collected; chart core Sun-sign-only
- Astrology: LOCAL vs LIVE registry mismatch
- Universe Map Memory chamber: legacy CRUD UI
- Home / Daily Ritual: inverse text-size under a11y scaling
- Premium: cancel/pending/restore-none success-style snackbar

### Release proof

Coffee / Palm / SoulMate production E2E · StoreKit monthly/yearly · restore · server entitlement verification

---

## Next action

**ChatGPT / product-owner review of Phase 2.1** before **Phase 3**.

Do **not** start Phase 3 until that review.
Do **not** mark future items completed until verified.
