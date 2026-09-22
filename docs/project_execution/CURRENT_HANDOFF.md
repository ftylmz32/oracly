# CURRENT HANDOFF

**Living state — factual only**  
**Updated:** 2026-09-22 Night Shift (docs + Tarot Phase 0 read-only)

---

## Repository

| Field | Value |
|---|---|
| Remote | `https://github.com/ftylmz32/oracly.git` (`ftylmz32/oracly`) |
| Active remediation branch | `fix/final-product-remediation-20260922` |
| Active worktree | `D:/oracly_final_r1` |
| Current HEAD | `173d75228248baf32ea0d4f04fe936665efff342` |
| `release/ios-1.0` HEAD | `1b7151dca954f0cc25f39f815c0dacf0613a1164` |
| Build 4 state | Untouched — commit `1b7151dc` *chore(ios): prepare App Store build 4* remains on `release/ios-1.0` |

Pre-existing local noise on active worktree (do **not** stage/clean):  
`design/runtime/astrology_runtime.png`, generated plugin registrants, possible line-ending dirt, `tool/qa/`.

---

## Remediation completed

### R1 — Privacy / Discovery History connected-memory purge

| | |
|---|---|
| Status | **PASS** |
| Commit | `764e7b04bb43c7ae792d51d813d38ceb5dd70b94` |
| What was fixed | Discovery clear also purges connected Coffee / Palm / Dream memory so cleared history cannot ghost into future AI context. |

### R2 — Tarot production fail-closed

| | |
|---|---|
| Status | **PASS** |
| Commit | `6fe6a74f6e1250605198b4ff8c5018d2dcebce6b` |
| What was fixed | Production Tarot no longer synthesizes canned local success after provider/quality exhaustion; unconfigured release cannot boot silent `LocalInterpretationExecutor`; uses `allowsLocalFallback` policy. |

### R2.1 — Tarot retry-path quality bypass closure

| | |
|---|---|
| Status | **PASS** |
| Commit | `173d75228248baf32ea0d4f04fe936665efff342` |
| What was fixed | Force-refresh retry path must re-run `AiOutputQualityTarot` and fail closed when quality still fails (no quality bypass). |

---

## Latest verified baselines

| Suite | Result |
|---|---|
| Flutter (client) | **3627** passed · **0** failed · **15** skipped · **0** timed out |
| Backend (known baseline) | **658** passed · **0** failed · **1** skipped |

---

## Project memory (this Night Shift)

| Artifact | Status |
|---|---|
| `docs/project_execution/ORACLY_MASTER_OPERATING_CONTRACT.md` | CREATED |
| `docs/project_execution/CURRENT_HANDOFF.md` | CREATED / living |
| `docs/project_execution/PROMPT_LEDGER.md` | CREATED |
| `docs/project_execution/WORKSPACE_INVENTORY.md` | CREATED (read-only) |
| `docs/product/tarot/TAROT_PHASE0_FORENSIC_BASELINE.md` | COMPLETE READ-ONLY |

---

## Open canonical backlog (NOT completed)

### P1

- **Yildizname / Birth Chart:** exact time/place collected but chart core is Sun-sign-only.
- **Astrology:** LOCAL catalogue / sun-sign behavior vs LIVE registry presentation mismatch.
- **Universe Map Memory chamber:** reachable legacy CRUD / admin-feeling UI.
- **Home / Daily Ritual:** inverse text-size behavior under accessibility scaling.
- **Premium:** cancel / pending / restore-none uses success-style snackbar.

### Release proof (required before public submit)

- Coffee production E2E  
- Palm production E2E  
- SoulMate production E2E  
- Real iOS StoreKit monthly / yearly purchase  
- Restore  
- Server entitlement verification  

### Product program

| Program | Status |
|---|---|
| Narrative Tarot Engine | **NOT IMPLEMENTED YET** |
| Tarot Visual System (locked golden set) | **NOT IMPLEMENTED YET** |

Tarot Phase 0 forensic baseline is documentation only — it does **not** implement Narrative Tarot or the Visual System.

---

## Next action

**ChatGPT / product-owner review of Tarot Phase 0** before **any** Tarot implementation (Phase 1+).

Do **not** mark future items completed in this document until verified.
