# CURRENT HANDOFF

**Living state â€” factual only**
**Updated:** 2026-09-22 â€” Tarot Phase 1 architecture/spec

---

## How to read SHAs in this document

Do **not** treat this file as a live pointer to the branch tip.

| Concept | Value | Meaning |
|---|---|---|
| Canonical branch | `fix/final-product-remediation-20260922` | Active remediation branch |
| Active worktree | `D:/oracly_final_r1` | Where remediation docs/code land |
| Last verified **application/code** baseline | `173d75228248baf32ea0d4f04fe936665efff342` | R2.1 â€” last Flutter-verified code tip (3627/0/15/0) |
| Phase 0 documentation baseline | `7155ad8535bd051a152437757fd11296b243de0b` | Night Shift docs tip at Phase 1 task start |
| `release/ios-1.0` | `1b7151dca954f0cc25f39f815c0dacf0613a1164` | Build 4 â€” untouched |

**The authoritative current branch tip must always be obtained from `git rev-parse HEAD` / origin branch tracking â€” not inferred from this document.**

Updating this handoff must **not** trigger recursive commits solely to refresh a â€œCurrent HEADâ€ field.

---

## Repository

| Field | Value |
|---|---|
| Remote | `https://github.com/ftylmz32/oracly.git` (`ftylmz32/oracly`) |
| Active remediation branch | `fix/final-product-remediation-20260922` |
| Active worktree | `D:/oracly_final_r1` |
| Build 4 state | Untouched â€” `1b7151dc` on `release/ios-1.0` |

Pre-existing local noise (do **not** stage/clean):
`design/runtime/astrology_runtime.png`, generated plugin registrants, possible line-ending dirt on tests, `tool/qa/`.

---

## Remediation completed

### R1 â€” Privacy / Discovery History connected-memory purge

| | |
|---|---|
| Status | **PASS** |
| Commit | `764e7b04bb43c7ae792d51d813d38ceb5dd70b94` |
| What was fixed | Discovery clear also purges connected Coffee / Palm / Dream memory. |

### R2 â€” Tarot production fail-closed

| | |
|---|---|
| Status | **PASS** |
| Commit | `6fe6a74f6e1250605198b4ff8c5018d2dcebce6b` |
| What was fixed | No canned local success after provider/quality exhaustion; unconfigured release fail-closed. |

### R2.1 â€” Tarot retry-path quality bypass closure

| | |
|---|---|
| Status | **PASS** |
| Commit | `173d75228248baf32ea0d4f04fe936665efff342` |
| What was fixed | Force-refresh retry must re-check quality; fail closed if still failing. |

---

## Tarot product program

| Phase | Status |
|---|---|
| Phase 0 â€” Forensic baseline | **COMPLETE** (read-only docs) |
| Phase 1 â€” Narrative product + architecture spec | **COMPLETE** (docs only â€” this task) |
| Runtime Narrative Tarot Engine | **NOT IMPLEMENTED** |
| Tarot Visual System (locked goldens) | **NOT IMPLEMENTED** |

### Phase 1 artifacts

- `docs/product/tarot/NARRATIVE_TAROT_SPEC.md`
- `docs/product/tarot/NARRATIVE_TAROT_DATA_CONTRACT.md`
- `docs/product/tarot/NARRATIVE_TAROT_MIGRATION_PLAN.md`

---

## Latest verified baselines

| Suite | Result |
|---|---|
| Flutter (at code baseline `173d7522`) | **3627** passed Â· **0** failed Â· **15** skipped Â· **0** timed out |
| Backend (known) | **658** passed Â· **0** failed Â· **1** skipped |

---

## Project memory

| Artifact | Status |
|---|---|
| `ORACLY_MASTER_OPERATING_CONTRACT.md` | CREATED |
| `CURRENT_HANDOFF.md` | LIVING (SHA semantics fixed) |
| `PROMPT_LEDGER.md` | LIVING |
| `WORKSPACE_INVENTORY.md` | CREATED |
| `TAROT_PHASE0_FORENSIC_BASELINE.md` | COMPLETE READ-ONLY |
| Narrative Tarot Phase 1 specs | COMPLETE (docs) |

---

## Open canonical backlog (NOT completed)

### P1

- Yildizname / Birth Chart: time/place collected; chart core Sun-sign-only
- Astrology: LOCAL vs LIVE registry mismatch
- Universe Map Memory chamber: legacy CRUD UI
- Home / Daily Ritual: inverse text-size under a11y scaling
- Premium: cancel/pending/restore-none success-style snackbar

### Release proof

Coffee / Palm / SoulMate production E2E Â· StoreKit monthly/yearly Â· restore Â· server entitlement verification

---

## Next action

**ChatGPT / product-owner review of Phase 1** before **Phase 2** (quality corpus + acceptance harness).

Do **not** start Phase 2 implementation until that review.
Do **not** mark future items completed until verified.
