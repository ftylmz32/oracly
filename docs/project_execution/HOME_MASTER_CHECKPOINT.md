# HOME Master Checkpoint

**HOME MASTER STATUS = NOT COMPLETE**  
**Date:** 2026-08-25  
**Gate:** HOME 11 / Master Release Gate  
**Scope:** Audit current Home after HOME 01–10 — no redesign, no new features, no Tarot start.

## Live path (preserved)

`OraclyAppShell` → `HomePage` → `HomeReferencePage` → `HomeReferenceBody`

Canonical OR: `OraclyFeatureId.aiChat` → `/chat` → `CompanionReferenceScreen`

## Composition (design hierarchy)

1. Header — official `OraclyBrandMark` + ORACLY wordmark + live gem capsule (non–first-session)  
2. Cinematic hero — real greeting + invite over hero plate  
3. OR flagship — `HomeReferenceOrFlagship` → `/chat`  
4. Bugünün İzi — real daily ritual card  
5. Discovery 3×2 — Coffee · Palm · Astrology · Yıldızname · SoulMate · Tarot  
6. Premium banner — honest `HomeReferencePremiumCard`  
7. Gems strip — real wallet banner (non–first-session only)  
8. Bottom nav — existing `OraclyBottomBar`

---

## HOME 11 — Master release checklist

| Requirement | Result |
|-------------|--------|
| Exactly one Home | PASS (code + KN8) |
| Approved ORACLY brand mark | PASS |
| Cinematic hero | PASS |
| OR flagship CTA | PASS |
| Bugünün İzi | PASS |
| Real discovery features | PASS (wired) |
| Premium state honest | PASS (copy/route) |
| Gems state is real | PARTIAL — wallet is real when shown; **hidden on first-session Home** |
| Navigation works | PASS when targets clear of nav; **FAIL hit targets on KN8 at rest** |
| Responsive | PASS (widget tests / KN8-class) |
| Accessible | PASS (focused a11y tests) |
| No overflow | **FAIL on TECNO KN8 at rest** (discovery bottom row + Premium under bottom bar) |
| No debug/reference/capture overlay | PASS |
| Performance acceptable | PASS (HOME 09; single cosmic; focused perf tests) |
| Focused Home tests | **PASS** — 69/69 (`test/features/home`) |
| `flutter analyze` (Home) | **PASS** — 0 issues (`lib/features/home`) |
| Full `flutter test` | Not re-run this gate (not required to decide; TECNO already fails) |
| TECNO visual gate | **FAIL** (HOME 10; code unchanged) |

---

## Remaining blockers (exact)

1. **TECNO KN8 — no overflow / hit targets:** At rest, discovery bottom row (Yıldızname · Ruh Eşi · Tarot) and Premium overlap/clip under `OraclyBottomBar`. Center taps hit the tab bar until the user scrolls. Evidence: `tool/device_home_gate/overlap_home.png`, `HOME10_REPORT.json`.
2. **TECNO KN8 — Gems on Home:** First-session gating hides header gem capsule and gems banner (`isFirstSession`), so the “Gems state is real” visual gate item cannot PASS on a fresh install.

Until both are resolved and TECNO visual gate is re-run to **PASS**, Home master release stays incomplete.

**Do not start Tarot.**

---

## HOME 10 summary (device)

DEVICE VERIFICATION = FAIL on TECNO KN8 (available). Destinations reachable after scroll; no crash/debug overlay/duplicate Home.

---

*End of HOME Master Checkpoint.*