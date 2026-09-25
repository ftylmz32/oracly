# YILDIZNAME Phase 3 — Owner Migration

**Canonical owner source:** `UserLocalDataIsolation.ownerKey` (`or_local_data_owner_uid`)

## Record field

`BirthChartRecord.ownerId` — nullable, backward compatible.

## Repository rules

`LocalBirthChartRepository(storage, {required ownerId})`:

| Situation | Behavior |
|-----------|----------|
| ownerId null/empty | `BirthChartOwnerUnavailableException` — **no wipe** |
| Record ownerId null + current owner ready | One-time adopt → stamp current owner |
| Record ownerId null + owner unresolved | **Not** adopted |
| Record owner A, context B | getLatest → null; save/clear fail closed |
| New save | Always stamp current ownerId |

## Account switch

Existing `UserLocalDataIsolation` + `UserLocalDataWipe` still removes `birth_chart_latest`.  
Repository hardening is defense in depth.  
`PrivacyDataRefresh.afterAccountSwitch` invalidates birth providers / rebuilds repo via `localDataOwnerEpochProvider`.

## Load safety

`BirthChartLoadStatus.ownerUnavailable`:

- Do not show another owner's data
- Do not `clearSavedData`
- Do not fabricate empty profile

## Legacy compatibility

Old JSON without `ownerId` / evidence fields decodes.  
Missing metadata stays missing — no fabricated place/timezone.

## Closed gaps (Phase 3)

- Evidence Acquisition Loop foundation
- Owner-aware birth input / persistence foundation

## Still open

- Phase 4: ephemeris / structured facts  
- Phase 5: interpretation / safety  
- Phase 6: immutable artifacts / stable favorite ids  
- Phase 7: final result chrome
