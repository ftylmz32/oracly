# TAROT Phase 7B — Shared Visual Primitives / Chrome Consolidation

**Status:** PASS candidate (see commit report)  
**Start HEAD:** `843cfec17a8b144f98f388159ee4de7bd880511e`  
**Branch:** `fix/final-product-remediation-20260922`

## Objective

Give the **live** Tarot table one coherent chrome foundation before 7C geometry / 7D ritual / 7E result work.

Not a redesign. Subtle token + ownership consolidation only.

## Live chrome ownership

| Role | Canonical owner |
|------|-----------------|
| Home entry | `TarotHomeScreen` → `TarotTableScene` |
| Table scene | `TarotTableScene` (own Scaffold + SafeArea) |
| Background | `TarotTableBackground` (+ `tarot_table_background_layers.dart`) |
| Tokens | `TarotTokens` (chamber + ritual card physicality) |
| Card shell | `RitualCardMetrics` → `TarotTokens.ritualCard*` |
| Motion | `OraclySignatureMotion` / `OraclyReducedMotion` |

### TarotScreenShell decision — **A**

`TarotScreenShell` remains **secondary / legacy / foundation** only.

Do **not** wrap the persistent live table through it. The table keeps its own shell so interaction model and continuous background stay intact.

## Dead / legacy quarantine (no mass deletion)

| Stack | Classification | Live import? |
|-------|----------------|--------------|
| `TarotBackground` + cinematic/particle stack | DEAD / UNREACHABLE from live table | **No** |
| Old home cinematic presentation | DEAD relative to live home | **No** |
| Old `CardRevealScreen` stack | Not on live home→table path | **No** |
| `TarotGlassCard` via `TarotScreenShell` | SECONDARY / foundation | **No** on live table |
| `TarotScreenShell` | SECONDARY | **No** on live table |

Files kept physically. Deprecation / role comments added on `TarotBackground` and `TarotScreenShell`.

## Token promotions (visual-only)

Added to `TarotTokens` when shared across live table chrome:

- Chamber: `tableVoid`, navy mid/deep, candle warm/deep, violet bloom, chip/reading plates
- Layout: `tableTitleTopGap`, `tableHintBottomInset`, `tableTitleTracking`
- Ritual card: `ritualCardWidth/Height/Radius/AspectRatio`

Globals reused where they already own the value:

- `AppColors.gold` (= candle warm)
- `AppColors.violetLuminous` (chip selected glow)
- `AppSpacing.md`
- `OraclyA11y.minTouchTarget` (44)
- `AppLayout.maxContentWidth` (unchanged)

Legacy `cardAspectRatio` / `cardCornerRadius` kept for selection/reveal paths — not the live ritual shell.

## Phase 6 firewall

No Narrative production, Result Contract, model/prompt, cache/retry, billing, backend, or live routing changes in this slice.

Crossroads remains picker/live excluded.

## Tests

- `test/features/tarot/ritual/phase7b_live_chrome_firewall_test.dart`
- `test/visual/tarot/tarot_table_chrome_baseline_test.dart`
- Existing Phase 7A visual harness (result baselines) unchanged in intent

## Out of scope (explicit)

7C geometry · 7D ritual redesign · 7E Narrative result redesign · asset regen · mass legacy deletion · shell migration
