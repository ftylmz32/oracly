# P3C — Coffee product quality

Live route: `OraclyRoutes.coffee` → `CoffeeV2EntryGate`.

- A new cup with a configured reading-operation sender opens `CoffeeV2FlowScreen`.
- `CoffeeReferenceScreen` stays live for `operationId`, `savedReadingId`, a legacy pending operation, and the no-transport fallback.
- `coffee_v2` is the production path for a new reading. It is not shadow and not test-only.
- V2 observing reuses `CoffeeLoadingView`, `CoffeeResultView`, and `CoffeeErrorView`. Capture inside V2 was not rewritten.

Provider, prompts, quality gates, and the reading-operation server contract were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Loading copy | `CoffeeLoadingView` accepted `message` and `subtitle` and then ignored them. The wait screen always showed the generic “your reading is being prepared” line. Both the legacy analyzing body and the V2 observing view pass cup-specific copy. | YES | Medium | `ReadingWaitScreen` takes optional `headline` and `detail`. Null keeps the shared line, so Palm is unchanged. Coffee passes its message and subtitle through. | `coffee_p3c_polish_test`, `coffee_flow_layout_test`, `coffee_target_ui_test` |
| History date | The history row built `day.month.year` for every language. Tarot and dream already use `OraclyFormat`. | YES | Medium | The row uses `OraclyFormat.dateCompact`, which follows the bound locale. | `coffee_p3c_polish_test` |

## Unchanged by design

- Landing camera calls `startCapture()` and opens the capture guide. The chamber camera opens from `CoffeeCaptureView`. The guide is intentional.
- Gallery cancel returns an empty intake. The phase stays on capture, no error is set, and an existing image is kept because intake only replaces the image when a new file arrives.
- Camera cancel on retake does the same: a null pick does not clear the selected cup.
- Hard image rejection still blocks analysis in `_analyze` via a second `CoffeeImageValidator` pass. Soft guidance stays a hint, not a failure. The two passes share one validator.
- `CoffeeEconomy.analysisCost` is null. `GemSpendGuard.beginPaid` does not ask for gems. Coffee is not blocked behind an unreachable balance. No free banner was added.
- `_starting` plus the analyzing-phase guard keep Use Photo to one submission.
- Acceleration still shows only while the server says waiting, prices only a real quote, and hides the CTA when the free wait is over or processing has started.
- A missing archived file is omitted. `CoffeeResultView` checks `File.existsSync` before the photo. The reading text stays.
- `previewBadge` and `capabilityNote` remain in `CoffeeCopy` and are not shown on the live screens.
- Store order is newest-first (`createdAt` descending).
- Coffee V2 capture flow was left as the live new-cup path. Only the shared wait copy it already tried to pass was restored.
