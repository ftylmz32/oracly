# TAROT Phase 7C — Spread Geometry System

**Status:** PASS candidate  
**Start HEAD:** `c39ae594a7a662eaad25ce06024f2c578af864b1`  
**Branch:** `fix/final-product-remediation-20260922`

## Objective

One presentation-only visual geometry authority for settled slots **and** flight placement targets.

## Authority

`lib/features/tarot/ritual/geometry/`

- `TarotSpreadVisualKind`
- `TarotSpreadGeometryResolver` (TarotSpreadType → kind → slots)
- `TarotSpreadGeometryLayouts` (normalized coords)
- `TarotSpreadSettledProjection` / `TarotSpreadFlightProjection`
- `TarotSpreadGeometryValidate`

Position keys bind via `SpreadEngine.positionsFor` — never invented.

## Mapping

| Spread | Visual kind |
|--------|-------------|
| single | single |
| threeCard | threeLinear |
| fiveCard | fiveLinear |
| sevenCard | seven |
| celticCross | celticCross |
| crossroads | fiveDecision |

`fiveDecision ≠ fiveLinear` — Crossroads never aliases fiveCard.

## Wiring

- `RitualSpreadSlots(spread: …)` — LayoutBuilder + Stack from geometry
- `placeTargetFor(spreadType)` — flight projection from same slots
- Old `spacing = 82` / fixed linear origin **removed**

## Firewalls

- Crossroads picker/live still false
- seven/celtic geometry defined, **not** added to table options
- Motion (CardFlightActor physics) unchanged
- Phase 6 Narrative untouched
- Phase 7B chrome ownership intact

## Tests

- `test/features/tarot/ritual/geometry/phase7c_spread_geometry_test.dart`
- `test/visual/tarot/tarot_spread_geometry_baseline_test.dart`
