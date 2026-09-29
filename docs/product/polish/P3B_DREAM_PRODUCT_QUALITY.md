# P3B — Dream product quality

Live path: Home → `openDream` → `DreamReferenceScreen` → entry hub → write or voice → organizing / reflecting → result, error, or safety.

Provider, model, safety policy, and backend were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Listen again | The review text was cleared before the microphone dialog returned. A denied or cancelled permission destroyed the transcript. | YES | High | `DreamVoiceDraft.listenAgain` returns first. The field clears only when a new recording phase actually starts. | `dream_p3b_polish_test` |
| Voice cancel | Back from the review called `voice.reset()` and left the transcript in the write field. | YES | High | `DreamVoiceDraft.abandon` clears the field only when leaving a transcribed review. A recording cancel keeps text that was already typed. | `dream_p3b_polish_test` |
| Save and close | The result button said “Kaydet ve kapat” / “Save and close” / “Сохранить и закрыть” and only popped. The dream is already stored before the result phase. | YES | Medium | Button uses `a11y.close` (Kapat / Close / Закрыть). No second write. | `dream_p3b_polish_test` |
| Edit Dream | Stored `Dream.entry` was wiped when editing, so chips and guided answers disappeared even though they were saved. | YES | Medium | `DreamEntrySelection.applyTo` restores them. A record with no entry still opens a clean form. | `dream_p3b_polish_test` |

## Unchanged by design

- Minimum narrative length stays 12 characters. Whitespace is trimmed before that check.
- The write field `maxLength` is `DreamEntryContext.narrativeMaxLength` (1000), and the counter uses the same maximum.
- `DreamEconomy.analysisCost` is null. `GemSpendGuard.beginPaid` does not ask for gems when cost is null. Economy copy already says a dream reading does not ask for gems. The stable attempt id remains. Not a release block.
- Organizing and reflecting share `DreamCopy.organizing`. There is no separate reflecting string. One waiting line, no percentage.
- Generic reflection stays the calm fallback when a closing line is absent. It is not presented as a symbol reading.
- Recent list shows two dreams. The discovery journal loads the full dream history.
- Voice “coming soon” copy is unused on the live screen. Live voice is the real capture path.
- Safety still skips gems, storage, and the normal result actions.
- OR themes still come only from the user’s narrative.
- Dream continuation is a cross-modal follow-up, not an unfinished-task flag for a completed dream.
