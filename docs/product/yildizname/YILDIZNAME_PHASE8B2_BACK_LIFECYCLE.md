# Yıldızname Phase 8B.2 — Back / Abandoned Route Lifecycle

Closes the last Phase 8B route-lifecycle gap: what happens when the user
leaves the Narrative live host before, during, or after a transaction.

REAL PROVIDER CALLS: 0

## Gaps closed

1. **Disposed post-frame.** `StarMapNarrativeLiveScreen.initState` schedules
   the first `_runFresh()` after the first frame. `_runFresh()` called
   `setState` with no entry guard, so a route removed before that callback
   could start provider work (or touch a disposed State).
2. **Stale history after Back.** Artifact-history invalidation lived in the
   screen's READY branch. A reading accepted and saved after Back was durable
   but `yildiznameArtifactHistoryProvider` stayed cached until an unrelated
   refresh.

## Back policy (frozen)

| When the user leaves | Behaviour |
|---|---|
| Before live execution starts | No provider call, no artifact, no analytics. |
| After the provider call started | The transaction finishes safely. An approved, persisted reading stays durable. |
| Any time after leaving | The host never calls `setState`, navigates, shows late success or error, or logs completion. |
| After a durable save | History is invalidated canonically, with or without a screen. |

Leaving the route abandons the **UI**, not the transport. There is no
cancellation flag: an already-started provider request cannot be cancelled,
and ORACLY does not pretend otherwise. An accepted, already-paid reading is
not thrown away because its screen closed.

## Screen lifecycle

`_live` = `mounted` **and** the hosting `ModalRoute` is still active. The
route check matters because a popped route stays mounted through its exit
transition; without it, a result landing in that window would render READY
and log completion on a closing screen.

- `_runFresh()` returns before any `setState`, `ref`, or `context` work when
  not live, and re-checks after the await.
- `_onRetry()` returns when not live.
- `_apply()` is only reached while live.

Normal Back is never blocked. No custom Navigator, no second route.

## Canonical history invalidation

`YildiznameLiveOrchestratorDeps.onArtifactPersisted` fires from
`YildiznameLivePersist.complete` only after:

1. the completion service returned an artifact, and
2. the post-save owner/epoch check passed.

It does not fire when the save failed (`persistencePending`), the owner
changed (the artifact is deleted by owner-race cleanup), or the flag turned
off before persistence. A semantic duplicate returned by the completion
service still counts as a durable artifact for the transaction, so it fires
too. A successful `retryPersistence` fires through the same path.

Production wiring (`yildiznameArtifactPersistedHook`) invalidates
`yildiznameArtifactHistoryProvider` through the Riverpod container, so a
rebuilt orchestrator `ref` cannot block it. The screen no longer invalidates
history, which leaves one canonical source. The core orchestrator imports no
Flutter widgets.

## Analytics

Completion analytics still fires only when a reading is actually shown
READY, once per host. Back during provider or persistence, followed by a
late save, logs 0. No retroactive event is emitted.

## Persistence pending + Back

When the provider result was accepted but the save failed, the host shows
the save error. If the user goes Back instead of Retry, the pending package
is discarded with the screen. The provider is not called again, there is no
background persistence retry, and no artifact is created. A later tap starts
a fresh transaction.

## Known behaviour (unchanged)

If the user goes Back during a provider call and taps the archive leaf
again before that call returns, the orchestrator is still busy with the
abandoned transaction. The new host shows the retryable generation error;
Retry works once the first transaction has finished.

## Tests

- `phase8b2_back_before_start_test.dart`: pop in the host's first frame,
  so no provider, artifact, analytics, or exception; the lock is released;
  the next tap starts fresh.
- `phase8b2_back_during_provider_test.dart`: Back during a held provider,
  then a late save, never shown, analytics 0; release inside the exit
  transition; re-entry works, and a dedupe still invalidates.
- `phase8b2_back_during_persist_test.dart`: Back during a held save gives
  one artifact and no late READY; persistence pending then Back gives no
  retry and no artifact.
- `phase8b2_back_error_test.dart`: Back from generation error,
  ownerChanged (A→B), and flagDisabled; then a fresh B tap or legacy with
  the flag off.
- `phase8b2_back_ready_test.dart`: READY then Back returns to the hub;
  analytics stays exactly once.
- `phase8b2_history_invalidation_test.dart`: the Riverpod history provider
  observes a post-Back save without restart; a control without the hook
  stays stale.
- `phase8b2_persist_notify_test.dart`: notify timing covering success,
  duplicate, failed save then retry, flag off, and owner change during save.

Every Back test runs the real `StarMapPrimaryLeafOpen.open` path: push,
pop, route Future, then navigation lock.

## Test artifact hygiene

`test/visual/hub_reference_capture_test.dart` rewrote tracked
`design/runtime/*_runtime.png` files on every run. It now writes there only
with `ORACLY_WRITE_RUNTIME_CAPTURES=1` (matching the existing
`YILDIZNAME_VISUAL_CAPTURE` / `TAROT_VISUAL_CAPTURE` opt-ins); otherwise it
writes to the system temp directory.

## Unchanged

Provider contract, attempt policy, quality validator, Narrative request,
semantic and evidence fingerprints, prepared owner/epoch transaction,
persistence-retry contract, Phase 7 presentation, astronomy, artifact schema.
