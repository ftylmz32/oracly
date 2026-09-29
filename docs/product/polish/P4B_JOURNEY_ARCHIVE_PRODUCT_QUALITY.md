# P4B — Journey archive product quality

Live Journal path: shell Günlük tab uses the legacy `OraclyTab.starMap` slot and mounts `DiscoveryJournalScreen`. `OraclyFeatureNavigation.open(discoveryJournal)` calls `OraclyNavigationService.openDiscoveryJournal`, which switches to that existing shell tab when a shell is present and otherwise pushes `/discovery-journal`. The enum name was left as-is.

Favorite Moments: `OraclyNavigationService.openFavoriteMoments` pushes `/favorite-moments` → `FavoriteMomentsScreen` → `FavoriteMomentOpener`.

My Story: `OraclyNavigationService.openMyStory` pushes `/my-story` → `MyStoryScreen`, derived from `personalDiscoveryProfileProvider`.

Reading History: `OraclyNavigationService.openReadingHistory` pushes `/reading-history` → `ReadingHistoryScreen()`. `showSampleData` stays false. The route does not pass sample data.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Journal continuation focus | `DiscoveryJournalScreen.build` called `consumeFor` on every build, including the loading frame. That cleared the one-shot theme before `DiscoveryJournalTimeline` existed. When entries arrived, the focus was already gone. | YES | High | The screen keeps the focus until a non-empty timeline can use it, then consumes it once. Loading, error, and an empty journal do not clear it. A focus aimed at another chamber stays stored. A later filter change is the timeline's own query. An unknown theme does not hide entries. | `p4b_journey_archive_polish_test` |

## Investigated, not changed

- Journal reopen still uses the stored id for Tarot (`id` or `sessionId`), Dream, Coffee, and Palm. A missing source shows `FavoriteMomentsCopy.sourceUnavailable` and does not open a fresh reading. SoulMate still requires the saved id, an authoritative interpretation, and portrait bytes.
- Favorite remove, missing-source fallback, and My Story loading/error/empty stay on their existing tests.
- Reading History production path does not enable catalogue sample data.
- Per-entry Discovery Journal delete for every non-Tarot source remains safely deferred. Feature stores still do not share one complete delete contract. No partial delete was added.
- OR, reading engines, owner wipe, Premium, and backend were not changed.

## Frozen

Tarot engine, Dream, Coffee, Palm, SoulMate, Yıldızname, OR, owner wipe, Premium/billing, and backend: unchanged.
