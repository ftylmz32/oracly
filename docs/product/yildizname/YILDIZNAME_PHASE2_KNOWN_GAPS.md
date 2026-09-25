# YILDIZNAME Phase 2 — Known Gaps



**Status:** Explicit ledger (not Phase 2 failures)  

**Classification:** `ContractGateResult.knownGap` / EXPECTED FUTURE FAILURE CONTRACT



Production currently lacks several Phase 1 end-state capabilities. Phase 2 **must not** treat them as harness failures. It must name them and assign ownership.



## Ledger



| Gap | Current fact | Owner phase |

|-----|--------------|-------------|

| ~~Ownerless birth storage~~ | **CLOSED Phase 3/6** — `BirthChartRecord.ownerId` + `yildizname_artifacts_v1` multi-artifact history | Phase 3 ✓ / Phase 6 ✓ |

| ~~No frozen artifact~~ | **CLOSED Phase 6** — immutable `YildiznameArtifact` (`yildizname_artifacts_v1`) | Phase 6 ✓ |

| ~~`Object.hash` favorite identity~~ | **CLOSED Phase 6** — `FavoriteMomentFactory.starMapArtifact` / durable `yid_…` | Phase 6 ✓ |

| ~~No Evidence Acquisition Loop~~ | **CLOSED Phase 3** — classifier + acquisition plan + place-unknown ask-once | Phase 3 ✓ |

| ~~No real ephemeris~~ | **CLOSED Phase 4** — `astronomia` + evidence-aware natal (`reducedNatal` / `fullNatalEphemeris`) | Phase 4 ✓ |

| ~~No production safety gate~~ | **CLOSED Phase 5** — `YildiznameQualityValidator` safety / grounding / prose gates | Phase 5 ✓ |

| ~~No structured future natal model~~ | **CLOSED Phase 4** — `NatalChartEvidence` structured placements/angles/houses/aspects | Phase 4 ✓ |

| ~~No interpretation craft~~ | **CLOSED Phase 5** — Narrative V1 request/result/quality/live engine (flag default false) | Phase 5 ✓ |

| Presentation of reduced/full disclosure | Minimal scope notes in Phase 3/4; final chrome | Phase 7 |



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

- ~~Interpretation engine (LLM never calculates sky)~~ **CLOSED**

- ~~Production safety gate~~ **CLOSED**

- ~~Groundedness / genericity quality gates~~ **CLOSED**



### Phase 6 — Artifact / history / stable ids / owner memory

- ~~Immutable artifacts~~ **CLOSED**
- Owner-keyed multi-artifact storage (birth slot remains single; artifacts are multi)
- ~~Durable favorite ids (replace `Object.hash`)~~ **CLOSED** (`starMapArtifact`)
- Memory truth persistence (Narrative V1 recurring themes)



### Phase 7 — Presentation

- Result architecture UI

- Scope disclosure chrome

- Locale labels without mutating facts



## How Phase 2 tests treat gaps



```dart

expect(YildiznameKnownGaps.ownerlessBirthKey.isKnownGap, isTrue);

expect(YildiznameKnownGaps.objectHashFavorite.isPass, isTrue); // CLOSED Phase 6

```



Future phases flip gaps to **fail** when the production contract is claimed complete.



## Non-gaps (already honest today)



These **pass** Phase 2 honesty regressions:



- `NatalChartCalculator` does not invent Moon / Asc / houses / aspects

- Birth time/place do not silently create full natal

- Legacy `degree: 0` / `house: 0` are placeholders, not precision

- Yıldızname vs Astrology registry distinction


