# P3G — SoulMate product quality

Live Home path: SoulMate tile → `OraclyFeatureNavigation.open` → `PremiumAccess.ensureFresh` → `SoulMateNavigation.open` → `SoulMateDrawScreen`.

- Free or inactive: after restore finishes with no portrait, the locked preview. Fresh generation stays behind Premium.
- Active Premium: the intake form, then a durable operation. This audit did not call a provider.
- Expired Premium with a saved portrait: the stored portrait stays readable. Redraw still asks for current Premium before the portrait is cleared.
- Exact `operationId`: `SoulMateReadingOrchestrator.recoverDurableOperation`. Unchanged.
- Journal: `DiscoveryJournalOpenHelpers.openSoulMate` checks the current saved id, then opens the same screen.

Portrait generation, interpretation, durable polling, and billing contracts were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Cold open | `showLockedPreview` was `locked && _result == null`. The first frames are null while restore is still running, so an expired member with a saved portrait saw the unlock preview. | YES | High | A quiet opening state stays up until the first restore settles. A finished null still shows the unlock preview. A restored portrait shows the result. An in-flight wait is not replaced by the preview. | `soul_mate_p3g_polish_test` |
| OR / continuation | The result epilogue always built `OracleReadingContextSources.soulMate` from empty parts when interpretation was missing. | YES | High | OR and continuation render only for an authoritative, non-empty interpretation. The portrait, retry, honesty line, and redraw stay. | `soul_mate_p3g_polish_test` |
| Redraw | `_redraw` cleared the portrait before `allowsFresh`. An expired member lost the saved view and landed on the unlock preview even though no new draw was authorized. | YES | High | Current Premium is checked first. A denial leaves the saved portrait and its stored row in place and shows the Premium sheet. | `soul_mate_p3g_polish_test` |
| OR chrome | `soulMate()` hardcoded Turkish source, chamber, and name labels into every locale. | YES | Medium | Chrome uses `soulmate.or.*`. The interpretation string passed in is copied as stored. Birth date, gender, and intention are still not part of this handoff. | `soul_mate_p3g_polish_test` |

## Investigated, not changed

- Home Premium single-flight and `ensureFresh` already block a false paywall and stacked sheets. Direct `SoulMateDrawScreen` still gates a new draw with `allowsFresh`.
- Share already sends interpretation text only when `parts.authoritative` is true.
- Journal mapping still requires a portrait plus an authoritative interpretation. Reopen still refuses a historical id that is no longer the saved portrait.
- Durable submit, exact recovery, stale-legacy retry, and the 3-second poll were left on their current contracts.
- Stored interpretation prose is not translated.
