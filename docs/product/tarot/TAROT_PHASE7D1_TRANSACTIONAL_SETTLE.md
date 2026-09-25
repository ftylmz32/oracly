# TAROT Phase 7D.1 — Transactional Reveal Settle + Localized Accessibility

**Start HEAD:** `d5b78ef11566d22cbfdf346e69c72b965f97798d`

## Defects

1. Visual settle committed before `advanceAfterReveal` persistence — domain
   rollback left ritual ahead of session.
2. `onFlightComplete` was fire-and-forget (`ValueChanged`).
3. CardFlightActor Semantics used hard-coded English.

## Fix

- Domain advance **before** visual `placed.add` (`TarotRitualSettle`).
- `Future<void> Function(RevealCardData)` awaited by actor.
- `RitualSettleOutcome` + in-flight guards; calm SnackBar retry (no redraw).
- Semantics: `tarot.ritual.stage.draw` + `tarot.ritual.draw_hint`.
