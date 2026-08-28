# HOME → TAROT Handoff

**Date:** 2026-08-25  
**Purpose:** Verify Home is closed before the next feature family. No product behavior changed in this handoff.

## Home final status

**NOT COMPLETE** — neither **COMPLETE** nor explicitly **BLOCKED**.

Canonical checkpoint: `docs/project_execution/HOME_MASTER_CHECKPOINT.md` (exists).

Home is **not** truly closed. Do not treat this handoff as permission to start Tarot until the blockers below are cleared and the master checkpoint reads `HOME MASTER STATUS = COMPLETE`.

### Closure checks

| Check | Result |
|-------|--------|
| Home Master Checkpoint exists | YES |
| Status COMPLETE or explicitly BLOCKED | **NO** — status is NOT COMPLETE |
| Known Home regression | YES — KN8 clip/hit + first-session Gems visibility (see blockers) |
| Duplicate live Home path | NO — live path only `OraclyAppShell` → `HomePage` → `HomeReferencePage` → `HomeReferenceBody` (epic030/epic032 not shell-wired) |
| Canonical navigation stable | YES for architecture; KN8 at-rest hit targets unstable until scroll |
| Focused Home tests green | YES — 69/69 (`test/features/home`, HOME 11) |
| `flutter analyze` Home | YES — 0 issues (`lib/features/home`, HOME 11) |

## Exact remaining external blockers

1. **TECNO KN8 overflow / hit targets:** At rest, discovery bottom row (Yıldızname · Ruh Eşi · Tarot) and Premium overlap/clip under `OraclyBottomBar`; center taps hit the tab bar until scroll. Evidence: `tool/device_home_gate/`.
2. **Gems on first-session Home:** Header gem capsule + gems banner gated by `isFirstSession` — Gems visual gate cannot PASS on a fresh install.
3. **TECNO visual gate:** FAIL (HOME 10); must re-run to PASS after fixes.

## Files changed by Home work (live / presentation)

Primary live surface:

- `lib/features/home/home_page.dart` — sole shell entry → reference
- `lib/features/home/reference/**` — `HomeReferencePage`, body, header, hero, OR flagship, Bugünün İzi, discovery grid, Premium, Gems, tokens, layout
- `lib/features/home/copy/**` — discovery / home copy where used by reference
- Related shared wiring preserved: daily ritual, bottom bar, feature navigation (not rewritten)

Docs / device artifacts:

- `docs/project_execution/HOME_MASTER_CHECKPOINT.md`
- `tool/device_home_gate/**` (HOME 10 device evidence)

Legacy epic030/epic032 trees remain in repo but are **not** the live Home path.

## Tests

- Focused: `flutter test test/features/home` — **PASS** (69 passed, HOME 11)
- Analyze: `flutter analyze lib/features/home` — **0 issues** (HOME 11)
- Full `flutter test`: not re-run at HOME 11/12 (environment optional; Home master already NOT COMPLETE)

## Next feature

**TAROT** — only after Home master status is **COMPLETE**.

---

*End of HOME → TAROT handoff.*