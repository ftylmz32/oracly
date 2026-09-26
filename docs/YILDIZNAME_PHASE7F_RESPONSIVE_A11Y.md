# Yıldızname Phase 7F — Responsive / Accessibility / Reduced-Motion

**Status:** implemented  
**Depends on:** Phase 7E + 7E.1 (`3a63c34a`)

## Purpose

Harden the frozen canonical result across compact→tablet viewports,
textScale 1.3 / 2.0, screen-reader headings, reduced motion, and long
localized chrome — without changing meaning, storage, or Phase 8 wiring.

## Production changes

- `ReadingExpandSection` — title is a semantic heading; continue-reading
  retains ≥44×44 with one button label node
- `ChamberStoryPanel` — reflection title is a semantic heading
- `ChamberReadingLane` — soft-reveal stagger capped (index clamp 0–3)
- `OraclyCrystalCapsule` — count max width capped so header FittedBox does
  not shrink the ≥44 interactive hit region under large balances
- Fact aspect rows — explicit softWrap

Horizontal gutters remain `StarMapReferenceTokens.screenHorizontal` after
audit: the required overflow matrix stays green at 320–768 without changing
frozen 7A–7E chrome.

## Goldens

Phase-scoped under `test/goldens/yildizname/phase7f/` only.
7A–7E masters untouched (7G owns master refresh).

