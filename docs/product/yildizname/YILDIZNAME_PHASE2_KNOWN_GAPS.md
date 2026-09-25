# YILDIZNAME Phase 2 — Known Gaps

**Status:** Explicit ledger (not Phase 2 failures)  
**Classification:** `ContractGateResult.knownGap` / EXPECTED FUTURE FAILURE CONTRACT

Production currently lacks several Phase 1 end-state capabilities. Phase 2 **must not** treat them as harness failures. It must name them and assign ownership.

## Ledger

| Gap | Current fact | Owner phase |
|-----|--------------|-------------|
| ~~Ownerless birth storage~~ | **CLOSED Phase 3** — `BirthChartRecord.ownerId` + owner-aware repo (key still single-slot; Phase 6 adds multi-artifact) | Phase 3 ✓ / Phase 6 remains for artifacts |
| No frozen artifact | Daily leaf / reading not immutable snapshot | Phase 6 |
| `Object.hash` favorite identity | `star-${Object.hash(title, insight)}` in star-map reference result | Phase 6 |
| ~~No Evidence Acquisition Loop~~ | **CLOSED Phase 3** — classifier + acquisition plan + place-unknown ask-once | Phase 3 ✓ |
| No real ephemeris | `NatalChartCalculator` = tropical sun sign only | Phase 4 |
| No production safety gate | Yıldızname-specific narrative safety not wired | Phase 5 |
| No structured future natal model | Full natal facts / houses / aspects not in production model | Phase 4 / 5 |
| Presentation of reduced/full disclosure | Minimal scope notes in Phase 3; final chrome | Phase 7 |

## Phase ownership map

### Phase 3 — Evidence / completeness / owner input
- Birth evidence model
- Completeness classification (production E0–E4)
- Owner binding foundations
- Evidence Acquisition Loop

### Phase 4 — Ephemeris + structured facts
- Real ephemeris
- Timezone resolution
- Structured placements / houses / aspects
- Authoritative astronomical fixtures (leave `PENDING_AUTHORITY` until sourced)

### Phase 5 — Interpretation / safety / quality
- Interpretation engine (LLM never calculates sky)
- Production safety gate
- Groundedness / genericity quality gates

### Phase 6 — Artifact / history / stable ids / owner memory
- Immutable artifacts
- Owner-keyed storage (replace `birth_chart_latest` wildcard)
- Durable favorite ids (replace `Object.hash`)
- Memory truth persistence

### Phase 7 — Presentation
- Result architecture UI
- Scope disclosure chrome
- Locale labels without mutating facts

## How Phase 2 tests treat gaps

```dart
expect(YildiznameKnownGaps.ownerlessBirthKey.isKnownGap, isTrue);
expect(YildiznameKnownGaps.objectHashFavorite.isKnownGap, isTrue);
```

Future phases flip gaps to **fail** when the production contract is claimed complete.

## Non-gaps (already honest today)

These **pass** Phase 2 honesty regressions:

- `NatalChartCalculator` does not invent Moon / Asc / houses / aspects
- Birth time/place do not silently create full natal
- Legacy `degree: 0` / `house: 0` are placeholders, not precision
- Yıldızname vs Astrology registry distinction
