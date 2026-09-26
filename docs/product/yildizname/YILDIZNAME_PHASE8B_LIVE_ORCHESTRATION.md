# YILDIZNAME PHASE 8B — Live Narrative Orchestration

**Status:** FROZEN when gates green  
**Flag:** `yildizname_narrative_v1` — **default `false`** (do not enable remotely in 8B)  
**Start HEAD:** `227cf1d89fcda70633f1af5a37b6c691f41b444e`

## Purpose

Wire frozen Phase 5–8A Narrative architecture into the **primary** Yıldızname archive leaf, behind the existing feature flag.

## Feature flag

| State | Behavior |
|-------|----------|
| false (default) | Exact legacy sky-message path (`StarMapResultOpen`) |
| true + E0/E1/E3 / legacy plan | Legacy path, **0** Narrative provider calls |
| true + E2/E4 eligible | Live Narrative orchestration |

Sibling routes (Karmic, Planets, Birth Chart) stay legacy.

## Semantic fingerprint freeze

For accepted Narrative readings:

```
semanticFingerprint = YildiznameRequestFingerprint.of(request)
```

i.e. the final canonical safe Narrative request fingerprint (language, scope, structured facts, merged discovery themes, request contract).

Separately:

```
evidenceFingerprint = plan.evidenceFingerprint
factsOnlyFingerprint = astronomical/theme-invariance diagnostic (not semantic identity)
```

## Orchestrator

`YildiznameLiveOrchestrator` (no BuildContext / Riverpod in core):

1. Capture owner + `accountSwitchEpoch`
2. Load authoritative chart via `BirthChartExperienceService` ports
3. Phase 8A `YildiznameLivePlanBuilder` (+ one local evidence repair)
4. Capability check → `YildiznameNarrativeLiveService` (max 2 attempts)
5. Owner/flag rechecks around provider + persist
6. `YildiznameNarrativeCompletionService.complete` with frozen fingerprints
7. `YildiznameArtifactPresentation.narrativeLive` + continuity + artifact-safe actions
8. Canonical `StarMapReferenceResultScreen` only

### Execution kinds

`legacyLocal` · `ready` · `ownerUnavailable` · `invalidEvidence` · `aiUnavailable` · `generationFailed` · `persistencePending` · `ownerChanged` · `flagDisabled`

### Persistence pending

If AI result is accepted but artifact save fails → `YildiznamePendingNarrativeCompletion`.  
Retry calls **completion only** (provider call count unchanged).

### No local fallback

Once Narrative execution begins, provider/quality failure never falls back to canned `StarMapReadingService` success.

## UI

`StarMapNarrativeLiveScreen`: Loading (`StarMapLoadingCinema`) → Error (`StarMapErrorState` + ResilienceCopy) → Ready (`StarMapReferenceResultScreen`).

Live presentation: `source = narrativeLive`, **no** historical badge.  
Reopen: `narrativeArtifact` + historical status.

## Analytics

`logStarMapCompleted()` once on Narrative ready (after durable artifact). Failures do not log completion.

## Tests

Automated tests use Fake AI / generate overrides. **REAL PROVIDER CALLS: 0.**

Hub golden pumps pin `StarMapReferenceScreen(now: DateTime.utc(2026, 9, 26))` so Phase 7G hub masters stay date-stable without updating PNG hashes.

## Phase 8C deferred

- Remotely enable Narrative flag  
- Production rollout / percentage  
- Real provider smoke  
- Telemetry threshold decisions  
