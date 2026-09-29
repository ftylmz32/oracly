# P3D — Palm product quality

Live path: Home → `openPalm` → `PalmReferenceScreen` → `PalmLandingView`.

There is no second live Palm screen. Saved reopen and exact `operationId` stay on `PalmReferenceScreen`. History is the shared discovery journal, not a Palm-only list.

Provider, prompts, quality thresholds, and the reading-operation server contract were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Loading copy | `PalmReferenceBody` passed `PalmCopy.analyzing` and `PalmCopy.analyzingHint` into `PalmLoadingView`. The view accepted them and then built `ReadingWaitScreen` without `headline` or `detail`, so the wait showed the generic reading line. | YES | Medium | Palm now passes those strings as `headline` and `detail`. Omitting them still shows the shared copy. Coffee already passes its own and was not edited. | `palm_p3d_polish_test` |
| OR chrome | The OR header shows `sourceLabel`, `readingTitle`, `deckName`, and `spreadLabel`. The local follow-up also speaks `fullInterpretation`. Those Palm fields were fixed Turkish (`El Falı`, `El yorumu`, `Genel:`, `Sağ el`). | YES | Medium | Labels use existing Palm and discovery keys. Reading body text is not translated. Wire hand stays `left` / `right`. | `palm_p3d_polish_test` |
| Hand label | `PalmHand.label` was `Sağ el` / `Sol el` for every language. The result title already used localized copy. The OR chip used `.label`. | YES | Medium | `.label` now reads `PalmCopy.leftHand` / `rightHand`. | `palm_p3d_polish_test`, `palm_vision_test` |
| Server hand side | Completed `_handSide` other than `left` was stored as the right hand. | YES | Medium | `PalmHand.fromWire` accepts only `left` and `right`. Anything else fails the restore instead of naming a hand. | `palm_restart_recovery_test` |
| New Palm | `backToEntry` cleared the image and reading but left `liveState` and acceleration quote/error in place. A later wait could show the previous operation. | YES | Medium | New Palm clears live state, acceleration error, cost, and price token. The selected hand stays until the user changes it. | `palm_restart_recovery_test` |

## Unchanged by design

- Landing camera still opens the capture guide. The chamber camera opens from the capture view.
- Gallery or camera cancel does not replace an existing image and does not set an error.
- Hard validation still blocks Analyze. Soft guidance stays a hint.
- `PalmEconomy.analysisCost` is null. `GemSpendGuard.beginPaid` does not ask for gems. Palm is not blocked behind a balance.
- `_starting` plus the analyzing-phase guard keep Analyze to one submission.
- Acceleration still prices only a quote for the current operation. Processing and overdue hide the CTA.
- A missing archived file is omitted. `PalmResultView` checks `File.existsSync` before the photo.
- Result titles already used persisted `reading.hand`, not the live selector.
- Retry label is `palm.retry_analysis` when the same photo can be sent again, and `palm.choose_another_photo` when it cannot.
- Back from analyzing pops the route. The durable operation stays recoverable. Back from capture, error, or result returns to the landing.
- Palm has no dedicated history screen and no manual `day.month.year` stamp. Journal dates stay on the shared formatter.
- Pending local recovery still treats a missing pending hand string as right only when the client itself wrote that record. The server restore path no longer does that.
- Coffee wait copy and Coffee OR labels were not edited.
