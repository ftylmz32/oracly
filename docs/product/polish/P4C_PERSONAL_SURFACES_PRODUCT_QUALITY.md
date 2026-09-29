# P4C — Daily Message, Personal Insights, Memory

Start: `585cf0a2432c6609ac7cc9328d88203b9479eafe`
Branch: `fix/final-product-remediation-20260922`

## Live paths

- Daily Message: `OraclyNavigationService.openDailyMessage` → `/daily-message` → `DailyMessageScreen` → `DailyMessageSession.resolve` → `DailyReturnStore`. Home teaser and Profile daily card also resolve the same store. Home already waits until profile, discovery, and settings have settled. Profile did not.
- Personal Insights: `openPersonalInsights` → `/personal-insights` → `PersonalInsightsScreen` → `personalInsightsControllerProvider`.
- Memory: `OraclyFeatureNavigation.open(memory)` → `MemoryScreen` → `memoryServiceProvider` → `MemoryService` → shared `LocalStorage` (`user_memories`).

## Confirmed defects

| Path | Wrong behavior | Proof | Fix |
| --- | --- | --- | --- |
| Daily Message and Profile daily card | First frame while profile, discovery, or settings are still loading resolves a generic snapshot and `persist` makes it canonical for the day. | Held providers: cinematic loading, store empty, then a themed profile. Stored text contains the real theme. A cached today snapshot still shows immediately. | Persist only when today's cache exists or all three inputs have a value or a terminal error. |
| Personal Insights regenerate | `load()` swallows errors into the error phase, then the sheet always shows the success snackbar. | Failing fake service: error phase and Retry, no `insights.regen_ok`. | Confirm only for ready or empty. |
| Insights hide / delete | `setStringList` returning false was ignored, then the sheet confirmed success. A failed second delete write could also split hidden and deleted sets. | Selective storage: hide false leaves the set empty. Delete that fails the hidden write rolls the deleted set back. | Return the storage bool. Confirm only when the write and the following load succeed. |
| Memory edit | Remove-then-add can drop the original when the replacement write returns false, or when the new text duplicates another row. | Flaky `setStringList`: `updateMemory` returns false and the original row, category, importance, and `createdAt` remain. Screen edit shows the failure copy and the original note. | One `updateMemory` write. `removeMemory` returns false when the delete write fails. |
| Daily Message at 320 | Save-favorite row overflowed by 14px. | Short-phone pump at 320, 360, and 390 with text scale 1.4. | The favorite label wraps instead of overflowing. |
| Insights chrome | Category labels, the card “more” label, and export section titles were fixed Turkish. | EN export contains Growth and Recurring patterns, not Desenler. RU export contains Рост. | Existing l10n tables. |

## Left unchanged

- Daily catalogue, composer, and picker.
- Reflection algorithms.
- Home teaser already refuses to persist while those providers are loading or in error.
- Reading History, Journal, favorites archive, OR, engines, billing, backend.
- Owner wipe. Daily keys already match the `daily_return_` prefix. Memory and insights preference keys are already listed. `memory_service_test` account isolation passed.
- Per-entry journal delete remains outside this phase.

## Tests

Focused suites passed, including the held-loading daily snapshot, regenerate/hide honesty, memory durability, existing daily/return/handoff tests, `personal_insights_test`, and `memory_service_test`.

`flutter analyze --no-fatal-infos` on the changed Dart files: no warnings. Two pre-existing infos remain on the insights experience constructor.
