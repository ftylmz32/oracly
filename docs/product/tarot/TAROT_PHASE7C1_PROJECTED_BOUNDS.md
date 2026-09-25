# TAROT Phase 7C.1 — Spread Geometry Projected-Bounds Hardening

**Start HEAD:** `66fa914dda74375459160d85d65c0c6a4fcac0b7`

## Defect

`TarotSpreadSettledProjection.centerOf` used a fixed fraction of the field
(`0.42` / `0.38`) and ignored the rendered tile extent
(`cardSize + labelChromeAllowance`). With `Clip.hardEdge`, Crossroads
top/bottom tiles clipped silently — no Flutter overflow exception.

## Fix

Extent-aware projection:

```
usableHalf = (field - tile) / 2
center = fieldCenter + n * usableHalf
```

API: `tileSizeFor`, `centerOf(slot, field, tileSize)`, `rectFor(...)`.

Validation: `TarotSpreadGeometryProjectionValidate` at 320/390/412.

## Regression proof

`phase7c1_projected_bounds_test.dart` reconstructs START HEAD math and
asserts legacy top edge `< 0`, then proves remediated rects are contained.
