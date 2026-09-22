# CURRENT HANDOFF

**Living state — factual only**
**Updated:** 2026-09-22 — Tarot Phase 3B2 Narrative Cups profiles

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
| Phase 3B2 task start | `66e814ebac1e84ea6ee556030d8f7af93be7daed` | Cups start |
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
| Phase 3B+ — Swords / Pentacles / Evidence Engine | **NOT STARTED** |
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
| V2 profile coverage | **50 / 78** |
| Major | **22 / 22** |
| Wands | **14 / 14** |
| Cups | **14 / 14** |
| Swords | **0 / 14** |
| Pentacles | **0 / 14** |
| Narrative Evidence Engine | **NOT IMPLEMENTED** |
| Runtime V2 | **NOT USER-REACHABLE** |
| Canonical deck | Unchanged (78 / 22 / 56) |
| Current Tarot user path | Unmodified |

Production surface:

- `lib/features/tarot/narrative/domain/` — models + validator + symbol tags
- `lib/features/tarot/narrative/data/` — catalog + Major + Wands + Cups profiles
- Tests: `test/features/tarot/narrative_domain/`

### Spec artifacts

- `docs/product/tarot/NARRATIVE_TAROT_SPEC.md`
- `docs/product/tarot/NARRATIVE_TAROT_DATA_CONTRACT.md`
- `docs/product/tarot/NARRATIVE_TAROT_MIGRATION_PLAN.md`
- `docs/product/tarot/NARRATIVE_TAROT_QUALITY_STANDARD.md`

### Phase 2 artifacts

- Canonical corpus: `test/fixtures/narrative_tarot_v2_corpus.json`
- CONTRACT HARNESS (test-only): `test/support/narrative_tarot_v2/`
- Tests: `test/features/tarot/narrative_v2/`

---

## Latest verified baselines

| Suite | Result |
|---|---|
| Flutter (at code baseline `173d7522`) | **3627** passed · **0** failed · **15** skipped · **0** timed out |
| Flutter (Phase 3A — PL-T3A) | **3662** passed · **0** failed · **15** skipped · **0** timed out |
| Flutter (Phase 3B1 — PL-T3B1) | **3669** passed · **0** failed · **15** skipped · **0** timed out |
| Flutter (Phase 3B2 — PL-T3B2) | **3676** passed · **0** failed · **15** skipped · **0** timed out |
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

**ChatGPT review before Swords.**

Do **not** start Swords until that review.
Do **not** mark future items completed until verified.
