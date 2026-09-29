# P4A — OR product quality

Live path: `OraclyNavigationService.openChat` → root `/chat` → `CompanionReferenceScreen` → `CompanionReferenceChamber` → `CompanionReferenceOrShell`.

Fresh entry with no reading clears `OrChatHandoffBuffer` and `clearReadingContext`. A typed handoff is offered, then taken once on the screen. Dispose interrupts TTS and releases proxy speech caches.

Provider, model, prompts, quality, depth, safety, retry budget, turn idempotency, owner guard, conversation writes, account-switch wipe, handoff payload, premium verifier, billing, and backend were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Premium cold open | `PremiumStatusController` starts unloaded and inactive. The first OR build treated that as a free chamber, so an empty room showed the free preview and a room with messages could show the Premium dock before the saved status finished. | YES | High | `OrSessionResolver.resolve(entitlementKnown: status.loaded)` holds compose, mic, preview, and dock until the first read finishes. An empty unknown chamber is blank. Existing messages stay in the thread. A finished inactive read shows the free preview. A finished active read shows the composer. | `or_p4a_polish_test` |
| Conversation after lapse | The conversation guard synced on init and when output mode became conversation. It did not listen to Premium. A stored Conversation mode (`isVoice`) could remain after entitlement lapsed. Comparing the same controller instance also skipped the sync, because both listen values already held the new state. | YES | High | After load, a Conversation mode without `CompanionVoiceConversationAccess` demotes to voice and shows `voiceConversationDemoted` once. Unknown entitlement does not demote. A later reconcile in voice or text does not snackbar again. | `or_p4a_polish_test` |
| Free menu Conversation | `showCompanionOrMenu` called `setMode(conversation)` directly. The output chip already used `CompanionVoiceConversationAccess.ensure`. The menu did not, so a free tap selected Conversation until the guard demoted it. | YES | Medium | Turning Conversation on calls `ensure(hostContext)` before `setMode`. Denial shows the existing preview and leaves text mode. Turning Conversation off does not require Premium. | `or_p4a_polish_test` |

## Review access

Review access uses the same `loaded` / `isPremium` gate as commerce Premium. `isPremium` already includes an active reviewer grant. This phase did not call `POST /v1/review-access/activate`. `review_access_gate_test` still passes.

## P4A.1 — Palm structured handoff

Confirmed in-scope handoff defect, fixed in P4A.1.

`OracleReadingContextSources.palm()` writes `fullInterpretation` with the current localized Palm titles (`KALP`, `ZİHİN`, `YAŞAM`, `YÖN`, `EN ÖNEMLİ İŞARET`, `GÜÇLÜ TEMALAR`, and the English and Russian equivalents). `OracleContextMapper._palm()` still searched the old title-case Turkish prefixes (`Kalp:`, `Temalar:`, and the rest). The result stayed a `PalmAiContext`, but takeaway, heart, head, life, fate, and themes were empty. Carrying the text only inside `fullInterpretation` did not preserve the typed fields.

The mapper now reads those fields from the current `palm.*_title` labels in Turkish, English, and Russian. A context built in one language still maps after the bind changes. Palm UI, Palm generation, and the `OracleReadingContext` payload were not changed.

## Investigated, not changed

- Fresh `/chat` clear, typed handoff buffer, first-reading deepen consumption, send/retry, persistence retry, thread scroll, regenerate, microphone permission, and TTS engine stay on their existing contracts. The listed companion and G1 OR suites were re-run.
- Failure copy for offline and local save still uses `CompanionCopy.offline` and `CompanionCopy.saveFailed`.

## Frozen

OR provider, model, prompts, system instructions, quality thresholds, response depth, safety, retry budget, turn idempotency, owner guard, conversation write contract, account-switch contract, handoff payload, premium verifier, billing product IDs, and backend: unchanged.
