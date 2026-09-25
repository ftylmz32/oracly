# YILDIZNAME Phase 6 — History & Exact Reopen

**Status:** FROZEN

## Invariant

**SAVED ARTIFACT ≠ REGENERATED READING**

Reopen = read stored artifact. Never:

- call narrative provider
- recalculate astronomy
- run `StarMapReadingService.build`
- apply current locale / day / flag / discovery / writer version

## Capture

| Path | When |
|------|------|
| Legacy | Leaf open (sky/karmic/planets) soft-captures when owner available |
| Narrative V1 | Only after Phase 5 final quality validation |

Capture failure: reading still displays; durable favorite unavailable (no fake id).

## Dedupe

- Legacy: semantic key from source + day + section kind + sun sign id + content digest  
- Narrative: same semanticFingerprint + contentHash → return existing  
- Intentional new accepted content → new artifact

## Reopen surfaces

- Favorite with valid `yid_` → exact artifact screen  
- Discovery Journal artifact row → exact artifact  
- Missing artifact → honest unavailable / old BirthChartRecord hub fallback only  
- Old `star-<hash>` favorites → compatibility hub; never pretend exact artifact

## Presentation

Reuse `StarMapReferenceResultScreen` chrome.  
Section titles may localize; **stored prose must not**.  
No factRef / themeRef / machine metadata in UI.

## Environment mutations (must preserve prose)

locale TR→EN · day D1→D2 · flag true→false · memory M1→M2 · writer/calc version · birth profile edits
