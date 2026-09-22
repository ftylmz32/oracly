# WORKSPACE INVENTORY

**Mode:** READ ONLY — no cleanup, no delete, no move  
**Evidence date:** 2026-09-22  
**Primary source:** filesystem presence + `git worktree list` from registered trees + `git` metadata where `.git` exists

Registered worktrees (`git worktree list` evidence):

| Path | HEAD | Branch |
|---|---|---|
| `C:/Dev/oracly_new` | `87ca21b1` | `roadmap/monetization-release-audit` |
| `C:/Dev/oracly_ios_build4` | `1b7151dc` | `release/ios-1.0` |
| `C:/Dev/oracly_ios_release` | `d2108541` | `fix/functional-core-recovery-20260919` |
| `C:/Dev/oracly_latest` | `c3e4d470` | detached |
| `C:/Dev/oracly_new/.claude/worktrees/agent-a667ba88652d844e2` | `e86ecc9d` | `worktree-agent-a667ba88652d844e2` |
| `C:/Dev/oracly_release_ios_1_0_verify` | `8ce64aaa` | detached |
| `D:/oracly_final_r1` | `173d7522` | `fix/final-product-remediation-20260922` |
| `D:/oracly_legal_publish` | `778a7d49` | `docs/legal-pages-update` |
| `D:/oracly_rc_android_20f7d86` | `20f7d86b` | detached |

Remote for registered client trees: `https://github.com/ftylmz32/oracly.git`

---

## Active remediation

### `D:/oracly_final_r1`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | `fix/final-product-remediation-20260922` |
| HEAD | `173d75228248baf32ea0d4f04fe936665efff342` |
| DIRTY / CLEAN | DIRTY (known non-source noise only — not staged by Night Shift) |
| REGISTERED WORKTREE | YES |
| PURPOSE | Active final-product remediation worktree (R1–R2.1 + docs) — evidenced by branch/HEAD |
| STATUS | **ACTIVE** |

---

## Release / Build 4

### `C:/Dev/oracly_ios_build4`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | `release/ios-1.0` |
| HEAD | `1b7151dca954f0cc25f39f815c0dacf0613a1164` |
| DIRTY / CLEAN | DIRTY |
| REGISTERED WORKTREE | YES |
| PURPOSE | iOS Build 4 / `release/ios-1.0` checkout — evidenced by branch + Build 4 commit |
| STATUS | **PRESERVE** |

### `C:/Dev/oracly_release_ios_1_0_verify`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | (detached) |
| HEAD | `8ce64aaa5e1a144641720537824e2e3bf4f4d714` |
| DIRTY / CLEAN | DIRTY |
| REGISTERED WORKTREE | YES |
| PURPOSE | UNKNOWN (name suggests release verify; not treated as active remediation) |
| STATUS | **PRESERVE** |

---

## Other registered client worktrees

### `C:/Dev/oracly_new`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git repo (primary linked tree) |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | `roadmap/monetization-release-audit` |
| HEAD | `87ca21b1e0b3a9eecc2cbba797fa6b7d3dd611c7` |
| DIRTY / CLEAN | DIRTY |
| REGISTERED WORKTREE | YES |
| PURPOSE | UNKNOWN relative to Night Shift (not the remediation HEAD) |
| STATUS | **PRESERVE** |

### `C:/Dev/oracly_ios_release`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | `fix/functional-core-recovery-20260919` |
| HEAD | `d21085412c15ffcea9a92899a508e38d68370402` |
| DIRTY / CLEAN | DIRTY |
| REGISTERED WORKTREE | YES |
| PURPOSE | UNKNOWN (legacy recovery branch; do not use for Night Shift) |
| STATUS | **LEGACY-DO-NOT-DELETE-YET** |

### `C:/Dev/oracly_latest`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | (detached) |
| HEAD | `c3e4d470657d3baf4387e94980e443d2ac42084e` |
| DIRTY / CLEAN | DIRTY |
| REGISTERED WORKTREE | YES |
| PURPOSE | UNKNOWN |
| STATUS | **LEGACY-DO-NOT-DELETE-YET** |

### `C:/Dev/oracly_new/.claude/worktrees/agent-a667ba88652d844e2`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | `worktree-agent-a667ba88652d844e2` |
| HEAD | `e86ecc9d` |
| REGISTERED WORKTREE | YES |
| PURPOSE | UNKNOWN (agent worktree) |
| STATUS | **TEMP-REVIEW-LATER** |

### `D:/oracly_legal_publish`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | `docs/legal-pages-update` |
| HEAD | `778a7d496a53fca2a674edf8296b8eeae930eb59` |
| DIRTY / CLEAN | CLEAN |
| REGISTERED WORKTREE | YES |
| PURPOSE | Legal pages docs branch — evidenced by branch name |
| STATUS | **PRESERVE** |

### `D:/oracly_rc_android_20f7d86`

| Field | Value |
|---|---|
| EXISTS | YES |
| TYPE | git worktree |
| REMOTE | `https://github.com/ftylmz32/oracly.git` |
| BRANCH | (detached) |
| HEAD | `20f7d86b19704f92aef08a3b3322bd6357624f99` |
| DIRTY / CLEAN | DIRTY |
| REGISTERED WORKTREE | YES |
| PURPOSE | UNKNOWN (Android RC naming; detached) |
| STATUS | **LEGACY-DO-NOT-DELETE-YET** |

---

## D: build / cache / temp (not registered worktrees)

| PATH | EXISTS | TYPE | REGISTERED | STATUS |
|---|---|---|---|---|
| `D:/oracly_build_26091304` | YES | build artifact | NO | CACHE-REVIEW-LATER |
| `D:/oracly_build_26091305` | YES | build artifact | NO | CACHE-REVIEW-LATER |
| `D:/oracly_build_env_26091304` | YES | build artifact | NO | CACHE-REVIEW-LATER |
| `D:/oracly_build_env_26091305` | YES | build artifact | NO | CACHE-REVIEW-LATER |
| `D:/oracly_build_env_26091306` | YES | build artifact | NO | CACHE-REVIEW-LATER |
| `D:/oracly_gradle_cache` | YES | cache | NO | CACHE-REVIEW-LATER |
| `D:/oracly-gradle` | YES | cache | NO | CACHE-REVIEW-LATER |
| `D:/oracly_tmp` | YES | temp | NO | TEMP-REVIEW-LATER |
| `D:/oracly_tmp_flutter` | YES | temp | NO | TEMP-REVIEW-LATER |
| `D:/oracly-tmp` | YES | temp | NO | TEMP-REVIEW-LATER |
| `D:/oracly_release_candidates` | YES | unknown | NO | UNKNOWN |
| `D:/oracly_smux1_26091306_work` | YES | unknown | NO | UNKNOWN |

No git remote/branch/HEAD recorded for these unless a nested `.git` is discovered later — none probed beyond type heuristics above.

---

## C: adjacent oracly* folders (summary)

Many `C:/Dev/oracly_*` directories exist. **Only those with `.git` / worktree registration are treated as git trees.**

| PATH | EXISTS | TYPE | HAS `.git` | REGISTERED | STATUS |
|---|---|---|---|---|---|
| `C:/Dev/oracly` | YES | unknown | NO | NO | UNKNOWN |
| `C:/Dev/oracly_new_release_backup_20260902_192914` | YES | git repo | YES | NO | LEGACY-DO-NOT-DELETE-YET |
| `C:/Dev/oracly_client_release_build_26091303` | YES | build artifact | NO | NO | CACHE-REVIEW-LATER |
| `C:/Dev/oracly_client_release_build_26091304` | YES | build artifact | NO | NO | CACHE-REVIEW-LATER |
| `C:/Dev/oracly_*_freeze` / `*_work` / `*_checkpoint*` / `*_PRE_RECONCILE*` / `*_FINAL_RC*` / `*_PRODUCT_COMPLETE*` / `*_OR_BEFORE_VISUAL*` / `*_backend_candidate*` / `*_client_final*` / `*_client_candidate*` / `*_g4_probe*` | YES | unknown | NO (except where noted) | NO | LEGACY-DO-NOT-DELETE-YET or UNKNOWN |

**Purpose:** UNKNOWN unless evidenced by registration/branch above. Folder names alone are **not** treated as proof of purpose.

---

## Absolute rules from this inventory

- **WORKSPACES MODIFIED:** NONE (inventory read-only)  
- **WORKSPACES DELETED:** NONE  
- Do not clean, reset, stash, or delete any of the above as part of remediation or Night Shift.
