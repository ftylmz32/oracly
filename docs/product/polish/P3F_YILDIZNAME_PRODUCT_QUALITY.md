# P3F — Yıldızname product quality

Live hub: Home star-map tile → `openStarMap` → `OraclyRoutes.starMap` → `StarMapReferenceScreen` → `StarMapReferenceHubBody`.

- No birth record, after the read finishes: general archive and “Enter birth details”.
- Saved birth record: city, sun sign from that date, and “Open the archive leaf”.
- Primary leaf: `StarMapPrimaryLeafOpen` chooses the frozen legacy result or the prepared Narrative host. This audit did not call a provider.
- Legacy result: `StarMapReferenceResultScreen`.
- Stored artifact: `StarMapArtifactReopenScreen` reopens stored prose. Unchanged.

Birth Chart math, Narrative prompts, and artifact contracts were not changed.

## Findings

| Surface | Observation | Defect | Severity | Fix | Test |
|---|---|---|---|---|---|
| Cold start | The hub treated `birthInformationProvider.valueOrNull == null` as “no birth info”. While the future is still loading, that value is also null, so a saved record showed “Enter birth details” and opened the birth form. | YES | High | The primary step stays hidden until the read has a value. A refresh keeps the profile already known. A finished null still asks for birth details. The rest of the hub stays visible. | `star_map_p3f_polish_test`, `star_map_polish_v1_test` |
| Birth date in OR | `birthLine` forced `day.month.year` into the star-map handoff summary for every language. | YES | Low | The date uses `OraclyFormat.dateCompact`. Time and place stay. Coordinates stay out. | `star_map_p3f_polish_test`, privacy firewall, batch 2 |

## Investigated, not changed

- `birthInformationProvider` turns repository errors and an unavailable owner into null. The screen cannot tell a failed read from a real absence without changing that shared provider. Left unchanged so Birth Chart persistence stays as it is. A finished null still means “no saved birth info” on the hub.
- Narrative gate, prepare path, result body, artifact reopen, and menu routes were left on their current contracts.
- Star-map OR section chrome already uses `star.handoff.*`. Stored narrative prose is not translated.
