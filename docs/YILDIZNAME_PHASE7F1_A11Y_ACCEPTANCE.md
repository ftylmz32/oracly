# Yıldızname Phase 7F.1 — Final Accessibility Acceptance Proof

**Status:** PASS (acceptance proven; freeze ready)  
**Depends on:** Phase 7F (`71f1b8a5`)  
**Goldens:** 0 (7A–7F untouched; 7G owns master refresh)

## Why

Phase 7F implementation was accepted, but freeze required rendered-widget
proof for hit targets, ActivateIntent, footer semantic order, availability
matrices, headings, max-width reflow, and reduced-motion late content.

## Production defects found by acceptance (minimal fixes)

| Defect | Root cause | Fix |
|--------|------------|-----|
| Duplicate actionable semantics on footer links | Nested `Semantics(button)` + `OraclyPressable` Semantics | Single `OraclyPressable(label:)` + `ExcludeSemantics` on chrome (share/copy/favorite/feedback/continuation) |
| OR label missing / double speech | `OraclyGoldButton` Text not excluded | `ExcludeSemantics` on CTA label Text |
| App-bar heading speech ambiguous | `titleChild` not excluded under header Semantics | `ExcludeSemantics` around titleChild |
| Scope/continuity/closing heading absorbed body text | `Semantics(container)` merged children | `explicitChildNodes: true` |

## Proof coverage

| Area | Tests |
|------|-------|
| Fact toggle ≥44 + closed/open semantics | `phase7f1_fact_semantics_test.dart` |
| Continue + fact via ActivateIntent | `phase7f1_keyboard_activate_test.dart` |
| Footer hit targets incl. continuation + feedback @ 320×568 ts2.0 | `phase7f1_footer_targets_test.dart` |
| Real semantics DFS order + no-OR / no-Favorite | `phase7f1_footer_semantics_test.dart` |
| Header==true for major headings; no duplicate speech | `phase7f1_headings_test.dart` |
| 768 ≤560, 390→768 reflow, reduced motion | `phase7f1_responsive_motion_test.dart` |

## Notes

- Fact expand remains in reading content; footer order is independent.
- `SessionContinuationLink` is forced via cross-modal discovery profile override.
- ActivateIntent is invoked from a focused descendant of the control’s `Actions`.
