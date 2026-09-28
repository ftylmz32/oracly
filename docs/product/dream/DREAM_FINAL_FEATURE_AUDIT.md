# Dream — Final Feature Audit & Freeze

Branch `fix/final-product-remediation-20260922` · start HEAD `fc06a7442bfd281dcef0daba18f48ed4b1f1fa58`
Scope: Dream as one complete product feature. No provider calls, no deployment, no
model / prompt / writer-revision change, no quality-gate tuning, no redesign.
Everything below was read from production code and proven with synthetic fixtures
and a fake provider.

## ACTUAL USER FLOW

1. **Entry.** Every entry reaches `OraclyNavigationService.openDream` → `pushNamed('/dream')`
   → `DreamReferenceScreen`:
   - Home / feature grid (`OraclyFeatureNavigation`);
   - the Daily return CTA;
   - discovery recommendations (`DiscoveryRecommendationOpener`);
   - Journal entries (`DiscoveryJournalOpenHelpers.openDream`) and Saved moments
     (`FavoriteMomentOpener._openDream`). These two first resolve the record,
     call `controller.openSaved`, then push the route.
2. **Hub** (`DreamReferenceEntryHub`). It has **Write** (`DreamCopy.writeDream`),
   **Voice** (`DreamCopy.voiceTell`) and the recent list (`DreamCopy.previousDreams`),
   which comes from `DreamAnalysisController.history`.
3. **Write** (`DreamReferenceEntryView`). You type a narrative (up to 1000 characters),
   with optional chips and guided answers, then tap **submit** (`DreamCopy.submitCta`).
4. **Voice** (`dream_voice_v1` / `dream_voice_continuous`). Recording leads to an editable
   review. The review edits the same `TextEditingController` that submit reads, so the
   **edited** text is what gets analysed.
5. **Submit** (`_submit` → `DreamPaidSubmit.run`). The steps run in this order:
   1. Too short (< 12 characters) → a snackbar, and nothing else happens.
   2. Busy → ignored.
   3. Safety policy → local safety guidance. Nothing is attempted, sent or stored.
   4. `DreamAttemptStore.resolveId` produces a stable attempt id. `GemSpendGuard.beginPaid`
      then runs: Dream cost is `null`, so there is no confirmation and no debit.
   5. The controller submits under `PaidAiOperationBinder`.
6. **Loading.** Organizing (480 ms), then reflecting (`ChamberWaitingOrb`).
7. **Provider call.** `OpenAiPaidRequests.dream` sends Idempotency-Key
   `or-dream-<id>:ds-<digest>`. The backend binds the frozen writer:
   `gpt-6-astra`, `reasoning_effort: medium`, JSON mode, no temperature, replay slot
   `dream-sem:4c3-astra`.
8. **Client acceptance.** Output safety, the evidence guard and the premium delivery
   contract (summary, emotionalMeaning, mainInterpretation, personalConnection,
   closingTakeaway) run **before** any write. A failure here is a typed `invalidResponse`.
9. **Commit** (`DreamExperienceCommit`). A new Dream is written **record-last**: owner
   check → version root → owner check → record + connected memory → owner check → result.
   The record is the last write, so a failed or raced version root never produces a visible
   Dream. A reinterpret keeps its order: version appended → record rewritten.
10. **Result** (`DreamReferenceResultView`). It shows summary, meaning, symbols, emotional
    card, history, reflection, **Save to journal** and **Reinterpret**, the version host, a
    footnote, then **OR ask**, **Save & close** (pop) and **New dream**.
11. **Leave.** Back or **Save & close** pops the route. The next visit opens the hub (see D4).
12. **Reopen.** Journal, Saved or the hub list open the stored copy with no provider call and
    no charge.
13. **Reinterpret.** Creates a new version of the **same** Dream id. If it fails, Retry
    reinterprets again and Back returns to the retained reading (see D3).
14. **Privacy.** A Discovery clear or an account wipe removes records, memory, version
    chains and the attempt row. Any analysis in flight cannot re-persist.

## 1 · Inventory

| Layer | Canonical code |
|---|---|
| Screen / body | `dream_reference_screen.dart`, `dream_reference_session_body.dart` |
| Views | entry hub, entry view, voice recording/review/error, loading, result, error, safety |
| State | `DreamAnalysisController` (entry · organizing · reflecting · complete · error · safety), `DreamVoiceController` |
| Services | `DreamExperienceService`, `DreamInsightBuilder`, `DreamExperienceCommit`, `DreamHistoryReader`, `DreamOwnerGuard` |
| Submit / economy | `DreamPaidSubmit`, `DreamAttemptStore`, `DreamEconomy` (`analysisCost == null`) |
| Persistence | `LocalDreamRepository` (`dream_records`), `OraclyMemoryStore`, `ReadingVersionStore` |
| Privacy | `PrivacyDreamClear`, `UserLocalDataWipe`, `PrivacyDataRefresh` |
| Client ↔ backend | `OpenAiPaidRequests.dream`, `DreamRequestIdentity`; backend `dream-writer-model.ts`, `dream-request-identity.ts` |

## 2–25 · Seam results

| § | Seam | Result | Evidence |
|---|---|---|---|
| 2 | Navigation / entry | **Defect D4 fixed.** A finished session (result, error or safety) greeted the next visit. An error re-entry showed Retry over an empty field, which only produced "too short" (a dead CTA). | `dream_final_session_reentry_test` |
| 3 | Write flow | Input is retained on too-short; a double tap starts one analysis; a typed but unsent Dream is never saved; the field is capped at 1000 characters. | `dream_final_entry_guard_test` |
| 4 | Voice | Edited transcript is used. | `dream_voice_v1_test`, `dream_voice_continuous_test` |
| 5 | Safety before money / provider | Nothing is attempted, sent, stored or versioned. | `dream_phase3_*`, `dream_final_journey_def_test` E |
| 6 | Economy | **Dream is free by contract.** `DreamEconomy.analysisCost` is `null`. `PaidAiOperationCoordinator` returns a non-persisted settled stub and *throws* for billable non-Tarot operations. So there is no Gem debit path, no double charge and no refund path. The attempt id only provides idempotency. This is not ambiguous in code, so there is no audit defect here. | `dream_phase3_paid_submit_test`, `dream_attempt_idempotency_r8_test` |
| 7 | Astra through the client flow | The Flutter wire body (hint `gpt-4o` / `gpt-4o-mini` / none, key `or-dream-<id>:ds-<digest>`) produces one provider call: `gpt-6-astra`, medium, `json_object`, no temperature. The key lands in the `4c3-astra` slot; a retry replays with 0 calls. | `backend/tests/dream-final-client-flow.test.ts`, `dream_phase21_identity_test` |
| 8 | Loading lifecycle | Staleness is token-guarded. Leaving mid-analysis keeps the run and the return shows its result. | `dream_final_session_reentry_test`, `dream_controller_lifecycle_test` |
| 9 | Error / retry | network, timeout, 429, 5xx, invalidResponse (server parse / quality / Phase 2, 4A, 4B rejects), noConfiguration, unauthorized, authPending, appCheck: all end in a calm message with no technical text and nothing stored. The same narrative then retries into exactly one Dream. | `dream_final_failure_matrix_test` |
| 10 | Required AI sections | A missing section (any of the 5) or unsafe prose is rejected before storage. A complete reply survives reopen as AI provenance. | `dream_final_failure_matrix_test`, `dream_phase4b_*` |
| 11 | Result UX | Canonical hierarchy, reachable CTAs. | `dream_reference_result_test`, `dream_reference_layout_test` |
| 12 | Long TR / EN / RU | ~750–900 character dreams render with no overflow; the full text is stored. | `dream_final_journey_def_test` F, `dream_result_long_text_viewport_test` |
| 13 | Localization | Covered. | `dream_new_localization_test`, `dream_phase2_*language*` |
| 14 | Owner switch / ABA | Covered. In flight → nothing reaches either owner, and the narrative is cleared from screen. | `dream_phase1_owner_switch_test`, `dream_phase4a_owner_race_test`, `dream_final_journey_test` C |
| 15 | Clear / privacy | **Defect D5 fixed.** After a clear with the Dream screen open underneath (reachable via Gems → Premium → Privacy), the cleared narrative reappeared as an editable draft. | `dream_final_journey_def_test` D, `dream_phase1_privacy_clear_test`, `reading_version_dream_clear_test` |
| 16 | Save / reopen | No provider call, no charge. | `dream_final_journey_test` A, `dream_phase1_open_saved_race_test` |
| 17 | Reinterpretation | **Defect D3 fixed.** After a failed reinterpret, Retry started a *new analysis* of the write-field text, minting a second Dream id (a duplicate with the wrong identity), and Back dropped to the hub. | `dream_final_reinterpret_test` |
| 18 | History UI | Covered. | `dream_history_v1_test`, `dream_phase4a_presentation_test` |
| 19 | Connected memory | Covered. | `dream_soulmate_read_side_memory_test`, `dream_phase3_output_memory_test` |
| 20 | Persistence atomicity | **Defects D1 and D2 fixed; D2 hardened in Final Audit.1.** A new Dream is record-last, so a version-root failure means `repository.save` never runs (0 records even when rollback delete would also fail). This is ordering, not a transaction. | `dream_final_audit1_commit_order_test`, `dream_final_persistence_atomicity_test` |
| 21 | Cold start | History reloads from storage per controller; reopen by id only. | `dream_phase1_*`, `dream_final_journey_test` A |
| 22 | Rapid actions | Double submit, leave mid-run, clear in flight, owner switch in flight. | final tests above, `dream_phase1_inflight_test` |
| 23 | Release honesty | Covered. | `dream_release_honesty_p1_test` |
| 24 | Accessibility | The hub meets the 44 pt tap-target guideline and every state's targets are labelled. See the shared-button limitation below. | `dream_final_entry_guard_test` |
| 25 | Journeys A–F | A happy path · B provider failure + retry · C owner switch in flight · D privacy clear · E safety · F long multilingual. | `dream_final_journey_test`, `dream_final_journey_def_test` |

## 26 · FOUND DEFECTS

- **D1. A record write that resolved `false` was reported as success.**
  `LocalDreamRepository.save/delete` ignored the storage result. The UI showed a completed
  reading, the attempt row was released and a version root was seeded, but no record
  existed.
- **D2. A partial commit left orphans that retry duplicated.** When the version root failed
  after the record was saved, the error screen sat over a stored record and its memory. A
  retry of the same narrative then minted a second `dream_<ts>` id.
- **D3. Retry after a failed reinterpret ran the wrong operation.** It started a new
  analysis of stale write-field text, which either showed "too short" (a dead CTA) or
  created a duplicate Dream. Back lost the reading.
- **D4. A stale session on re-entry.** The global controller kept complete, error or safety
  after the route was left. Home, Daily and recommendation entries reopened the old screen,
  and the error variant offered a Retry that could only say "too short".
- **D5. A cleared narrative reappeared as a draft.** This happened after a Dream privacy
  clear while the Dream route stayed mounted underneath.

## FIXED DEFECTS

| # | Fix (narrow) | Files | Pre-fix proof |
|---|---|---|---|
| D1 | `setStringList(...).requireDurable(key)` in `save` and `delete` | `local_dream_repository.dart` | "a record write that resolves false…" failed (resolved as success); the controller test showed `complete` |
| D2 | **Final Audit.1:** a new Dream is committed record-last (version root → owner check → record + memory → owner check). The first version (revert after record-first) still depended on a rollback delete succeeding: if the root write failed *and* the delete failed, a visible record stayed and retry duplicated it. Now the record is never written unless the root is durable and the owner still holds. A failed record write deletes it and removes the root best-effort. | `dream_experience_commit.dart` | record / memory counts 1 instead of 0; retry produced 2 records; commit-level fake (save succeeds, root throws, delete throws) left an orphan and failed the record-first order (mutation M1) |
| D3 | The controller records a failed reinterpret (`reinterpretFailed`). Retry calls `reinterpret()`; Back calls `returnToReading()` | `dream_analysis_controller.dart`, `dream_reference_screen.dart` | a new Dream id was minted; phase went to `entry` on Back |
| D4 | Screen `dispose` schedules `releaseSession()`, which resets only settled phases; a running analysis is kept | same two files | result, error and safety views were found on re-entry |
| D5 | The screen clears its local draft when `DreamOwnerGuard.clearGeneration` advances (same path as an owner change) | `dream_owner_guard.dart` (read-only getter), `dream_reference_screen.dart` | the cleared narrative text was found after the clear |

No frozen interpretation contract, prompt, model, writer revision (`4c3-astra`), guard or
eval artifact was changed.

## KNOWN LIMITATIONS

- **Hidden version-root orphan (storage recovery).** Two cases can leave a Dream version root
  with no record behind:
  - the new-Dream record write fails *and* the best-effort `removeRoot` also fails;
  - the root write reports failure but its in-process cache kept the row.

  The root is keyed by an id that no record, history list, journal or UI references. It is
  invisible and is removed by privacy clear or account wipe. **No failed new Dream leaves a
  user-visible Dream record.** This is ordering plus best-effort cleanup, not a storage
  transaction.
- **A failed revision save.** A reinterpret whose record save fails *after* the version
  chain accepted the revision leaves that revision in the chain; the user sees an error.
  `ReadingVersionService` has no single-revision removal, and adding one would touch every
  feature. Data is not lost: the prior record is intact.
- **Same-content reinterpret.** A reinterpret whose provider body equals the current
  version adds no version (`lastVersionAdded == false`). A repeat within the server replay
  TTL returns the cached body. This is by design.
- **Shared error-state button (cross-feature).** The `OraclyErrorState` primary button
  (`PremiumButton`) measures 43 px in tests, and its semantics label is announced twice
  (the outer `Semantics` plus the inner button). This belongs to a shared component used by
  every feature, including frozen Tarot and Yıldızname, so it is deferred to the general
  product audit. The app-bar back button is 44×44, which meets the project ≥44 standard but
  not Android's 48 dp.
- **Voice review Back** keeps the transcript. It is non-destructive; the label is "Back".
- **Stacked Dream routes.** If a second Dream route is pushed over a mounted one and then
  popped, the underlying screen returns to the hub. Nothing is lost.
- **Log label.** The backend `ai_complete` log line labels the model with the generic
  `openaiModel` for Dream. The provider body is Astra (proven). Use `describeDreamConfig`
  for verification.

## NOT TESTABLE WITHOUT REAL DEPLOYMENT

- Real `gpt-6-astra` latency, availability, rate limits and prose quality on live traffic.
- Real Firestore replay durability and TTL; the Cloud Run env binding of
  `OPENAI_DREAM_MODEL` / `OPENAI_DREAM_REASONING_EFFORT`.
- On-device speech recognition (the `speech_to_text` platform plugin) and microphone
  permission UX.
- Real device fonts, screen readers (VoiceOver / TalkBack) and OS text scaling.
- App Check / auth token behaviour against the deployed proxy.

## 27 · POST-DEPLOY SMOKE CHECKS (minimal)

1. `describeDreamConfig` / the deployed env shows `OPENAI_DREAM_MODEL=gpt-6-astra` and
   `OPENAI_DREAM_REASONING_EFFORT=medium`.
2. One synthetic TR Dream from a test account produces a result with all five sections;
   Journal shows one entry.
3. Close and reopen from Journal: same reading, no new provider request in logs.
4. Airplane mode, then submit: a calm error. Reconnect and Retry: exactly one Journal
   entry.
5. Reinterpret once: the version host shows 2 versions of the same Dream.
6. Privacy → clear discovery history: Dream Journal is empty; reopening Dream shows an
   empty hub.

## 28 · Scope

No old large file was refactored; additions to `dream_reference_screen.dart` and
`dream_analysis_controller.dart` are minimal lines inside existing files. All new tests
live under `test/features/dream/dream_final_*` (including `dream_final_audit1_commit_order_test`) and
`backend/tests/dream-final-client-flow.test.ts`.
