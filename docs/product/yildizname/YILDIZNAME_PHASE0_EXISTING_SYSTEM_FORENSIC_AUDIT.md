# YILDIZNAME Phase 0 — Existing-System Forensic Audit

**START HEAD:** `475a4ca5cc1a17b13db0f53089c1efca4640658c`  
**Branch:** `fix/final-product-remediation-20260922`  
**REAL PROVIDER CALLS:** 0  
**Production files modified:** 0  
**Test files modified:** 0  

---

## Verdict

| Gate | Status |
|------|--------|
| YILDIZNAME PHASE 0 | **PASS** |
| NEXT PHASE READY | **YES** |

Tarot Phase 0–10 remains **COMPLETE / FROZEN** — not reopened.

---

## Executive answer

### What is Yıldızname today?

A **free, local, symbolic sun-sign archive** at `/star-map`.

Daily chapter text is deterministic catalogue composition from:

1. calendar day (device local `DateTime.now()`)
2. optional tropical sun sign from saved birth date
3. optional `PersonalDiscoveryProfile` recurring themes

It is **not** a live celestial calculator, **not** a full natal chart, and **not** AI-generated for the primary reading.

### What must change for a professional paid ORACLY feature?

Without fabricating sky facts:

1. treat birth time/place as **evidence completeness**, not decoration
2. plug a real astronomical calculation behind `ChartCalculationPort` when evidence allows
3. freeze historical readings as **artifacts** (today’s hub regenerates by day)
4. separate deterministic facts from narrative interpretation
5. add Evidence Acquisition Loop for missing time/place (ask once or reduce scope)
6. stabilize favorite identity beyond `Object.hash`
7. keep honesty: never invent Moon/Rising/houses/aspects

---

## 1. Live entry paths

| Path | Mechanism | Class |
|------|-----------|--------|
| Home Live grid → Yıldızname | `HomeReferenceModules` → `OraclyFeatureNavigation.open` | **LIVE** |
| Explore (Keşfet) | `ExploreReferenceScreen` → same nav | **LIVE** |
| Named `/star-map` | `OraclyRouteGenerator` → `StarMapReferenceScreen` | **LIVE** |
| Birth Chart nested | `StarMapReferenceRoutes.openBirthChart` → `MaterialPageRoute(BirthChartScreen)` — **no named route** | **SECONDARY LIVE** |
| Result chapters | `StarMapReferenceResultScreen` (sky / karmic / planets) | **LIVE** |
| Favorites reopen | `FavoriteMomentOpener` → `openStarMap` (hub, not exact leaf) | **SECONDARY LIVE** |
| Discovery Journal | map entry → `openStarMap` | **SECONDARY LIVE** |
| Share / deep link | `ShareFeatureOpen` → `/star-map` | **SECONDARY LIVE** |
| OR handoff | `OrAskButton` after section | **SECONDARY LIVE** |
| Shell tab `OraclyTab.starMap` | Actually Discovery Journal root — **not** Star Map | **MISNOMER / not star-map entry** |
| Legacy home discover sections | Not wired to live Home | **DEAD / TEST-ONLY** |

**Canonical screen:** `StarMapReferenceScreen`  
**Birth Chart path:** nested from hub only  

---

## 2. Feature registry

| Field | Value |
|-------|--------|
| ID | `OraclyFeatureId.starMap` |
| Title | `Yıldızname` |
| Subtitle | `Yerel · kişisel hikâye arşivi` |
| Route | `OraclyRoutes.starMap` = `/star-map` |
| Availability | `live` |
| Premium | `requiresPremium: false` |
| Realm | `understand` (`homeBand: understand`) |
| Engine / prompt / catalogue | **none** (unlike Astrology) |
| Truth label | Subtitle + copy: **local / symbolic archive** — not “PREVIEW” registry enum |

Consistency: honesty lives in copy (`StarMapPolishCopy`, `BirthChartCopy`, l10n), not a separate registry availability flag.

---

## 3. Input inventory

| Field | Entered | Persisted | Required | Used in calc | Display | Interpretation |
|-------|---------|-----------|----------|--------------|---------|----------------|
| Birth date | Birth Chart onboarding | `BirthProfile` in `birth_chart_latest` | Yes for chart | **YES** → sun sign | Yes | Sun-sign catalogue |
| Birth time | Onboarding if “known” | Yes | Conditional UI | **NO** | Yes (identity) | Unused |
| Time known flag | Choice row | Yes | Yes to proceed | **NO** | Indirect | Unused |
| Birth place / city | City picker (81 TR) | Yes | Optional notes | **NO** | Yes | Unused |
| Lat / lon | From city catalogue | Yes | No | **NO** | No (math) | Unused |
| Name | Not a dedicated Yıldızname field | — | — | — | — | — |
| Sun sign | Derived from date | Via chart + providers | Optional for hub | **YES** for tone salt | Yes | Voice head / sky |
| Discovery themes | Cross-feature history | Profile builder | No | Overlay only | Theme lines | Archive compose |
| Daily archive leaf | Generated live | **Not persisted** | — | — | Hub/result | Catalogue + compose |

**Unused inputs (collected but not calculated):** birth time, birth place, lat/lon.

---

## 4. Evidence map

| Item | Class |
|------|--------|
| Birth date | **A** USER PROVIDED FACT |
| Birth time / known flag | **A** then **F** UNUSED for calc |
| Birth place + lat/lon | **A** then **F** UNUSED for calc |
| Tropical sun sign from date | **B** DETERMINISTIC COMPUTED FACT |
| Element / modality from sun | **B** (catalogue mapping) |
| Calendar day tone / karmic index | **B** arithmetic seed |
| PersonalDiscovery recurring labels | **C** HISTORICAL ORACLY EVIDENCE |
| `StarMapCopy` / archive beats / planet catalogue | **D** SYMBOLIC CATALOGUE |
| Archive story composition / insights | **E** DERIVED INTERPRETATION |
| Moon / Rising / houses / aspects / planet longitudes | **F** UNAVAILABLE (empty) — not fabricated in UI when `hasFullNatal == false` |
| `sun.degree = 0`, `sun.house = 0` | Placeholder model fields — **hidden** from current UI (planets list gated) → treat as **harden risk**, not live overclaim |

---

## 5. Calculation engine

| Component | Role |
|-----------|------|
| `ChartCalculationPort` | Swappable port — **KEEP** |
| `NatalChartCalculator` | Only live impl — tropical sun from date |
| Fidelity | `ChartCalculationFidelity.tropicalSunSign` |
| `fullNatalEphemeris` | Reserved enum — no impl |

| Output | Status |
|--------|--------|
| Sun sign | **REAL CALCULATION** (`ZodiacSignId.fromDate`) |
| Sun degree | **PLACEHOLDER** `0` (hidden) |
| Sun house | **PLACEHOLDER** `0` (hidden) |
| Moon | **EMPTY** / null after sanitize |
| Ascendant / Rising | **EMPTY** |
| Planets list | **EMPTY** |
| Houses | **EMPTY** |
| Aspects | **EMPTY** |
| Element / modality | **CATALOGUE-DERIVED** from sun |
| Dominant energy | **CATALOGUE-DERIVED** |
| Life themes / insights | Filled by `ChartInsightGenerator` (local copy), not ephemeris |
| Real ephemeris | **NO** |

---

## 6–8. Honesty: degree, time, place

- **Degree/house:** stored on `Planet sun` but UI shows **sign name only**; planet/house lists render only if `chart.hasFullNatal`. → **hidden placeholder**.
- **Birth time known = true:** still ignored by calculator. UI copy explicitly: “not used yet / stored for Rising” (`birth.time_note`, `birth.stored_note`).
- **Place / lat/lon:** stored; “not used yet / local sky later” (`birth.place_note`).
- **Cities:** 81 Turkish provinces with real lat/lon for place metadata; file comment: coordinates for place, not sky math. Legacy 5 international cities for old profiles.

No live UI path claims computed Ascendant/Moon/houses when fidelity is tropical sun only (enforced by tests + `hasFullNatal` gates).

---

## 9–12. Reading generator & language

### `StarMapReadingService`

```
day = now ?? DateTime.now()  // device local
tone = (y*17 + m*29 + d + sign*13) % 3
  sign = sunSign.index OR day.weekday (never fake Aries)
karmicTheme = (y + m*13 + d) % 6
base = StarMapCopy.overview/sky/karmic/planets(tone)
return StarMapPersonalization.overlay(...)
```

| What changes | Driver |
|--------------|--------|
| Day-to-day | tone + karmic indices + archive seed |
| By sun sign | tone salt + “sun for …” labels |
| By discovery | focus themes into archive compose; insufficient → empty journey |
| Static | catalogue strings keyed by tone/theme |

**Planet sections:** `StarMapCopy.planets(tone)` — **symbolic catalogue**, not positions. Copy notes this (`planetsCatalogueNote` / honesty tests).

**“Karmic” language:** UI titles renamed away from “KARMİK ANALİZ” → themes / journey / threshold. Reflective, not destiny-certainty. Severity of residual “karmic” key names in code: **P3** (code keys vs user-facing titles).

---

## 13–14. Personalization & memory

| Kind | Exists? |
|------|---------|
| A. PersonalDiscovery recurring themes | **YES** — overlays Yıldızname |
| B. Saved birth profile | **YES** — in chart record |
| C. Saved BirthChartRecord | **YES** — `birth_chart_latest` |
| D. Favorites | **YES** — quote + reopen hub |
| E. Yıldızname reading history | **NO** dedicated list |
| F. Daily archive leaf history | **NO** — regenerated |

First user without themes: `PersonalThemeCopy.insufficient`; journey empty copy — **does not invent recent history**.

Owner scope: discovery builder uses local history sources; birth chart key has **no ownerId** on the prefs key → account-switch risk (**P1**).

---

## 15–17. Persistence & reopen

| Model | Key | Owner | Restart |
|-------|-----|-------|---------|
| Birth chart + profile | `birth_chart_latest` | **none on key** | Restores latest |
| Connected memory | `reading:birthChart:{id}` | memory factory | Journey upsert |
| Daily Star Map reading | — | — | Rebuilt each open |
| Favorites | `or_favorite_moments_v1` | wipe-aware | Persists quotes |
| Settings leftover | `astrology_birth_chart` in schema | unused for store | Schema-only |

**Save today:** BirthChartRecord (durable); FavoriteMoment (content clip); share highlight; **not** a frozen daily leaf.

**Reopen favorite/journal:** opens **hub**, which rebuilds **today’s** reading — not the saved day’s frozen artifact.

**Day change:** new tone/karmic indices; prior day’s leaf not stored → **lost as artifact**.

---

## 18–20. OR / share / favorite ID

**OR:** `OracleReadingKind.starMap` — section label, clipped section lines, birth line, sun-from-date line, `sessionId: star_map_$sectionLabel`, `deckId: star-map`. No lat/lon dump; no fake natal planets.

**Share:** highlight string only — low private surface.

**Favorite ID:** `star-${Object.hash(title, insight)}` → `starMap:$ref`.  
Content-stable **within** a process; Dart hash randomization across isolates/process runs can change `Object.hash` for equal strings → **potential cross-restart favorite identity defect (P1)**. Do not fix in Phase 0.

---

## 21. Localization

TR / EN / RU tables: `table_birth*`, `table_astrology` (star archive), `table_star_*`, city labels.  
Honesty strings localized.  
Risk: hardcoded fallbacks mostly avoided; city labels deterministic.  
Persistence identities are not locale-keyed for birth chart (good). Favorite hashes use localized title/insight → **locale change can change favorite id** (P2).

---

## 22. UI architecture

| Screen | Role |
|--------|------|
| `StarMapReferenceScreen` | **Canonical hub** + QualityLoopGate |
| Hub body / menus / chart chrome | Live presentation |
| `StarMapReferenceResultScreen` | Chapter result |
| `BirthChartScreen` | Nested onboarding + result |
| Onboarding / result widgets | Live |

No redesign in Phase 0. Visual chrome should **KEEP** pending later visual phase.

---

## 23. Quality loop

`QualityLoopGate(feature: starMap, startOnInit: true)` → recorder started/abandoned telemetry only; **does not** collect evidence or block content. Footer `ReadingQualityActions` = opinion signals.

**Not** Evidence Acquisition Loop.

---

## 24–26. Future boundary (conceptual)

| Evidence | Allowed calc | Forbidden invention |
|----------|--------------|---------------------|
| Date only | Sun sign (+ element/modality) | Moon, Rising, houses |
| Date + time unknown | Same reduced scope; ask once for time | Ascendant/houses |
| Date + time + place | Full natal via ephemeris port | Prose-computed longitudes |

`ChartCalculationPort` is the correct seam for a real ephemeris impl without rewriting presentation if fidelity/`hasFullNatal` gates stay honest.

**Deterministic engine owns:** longitudes, signs, houses, aspects, balances.  
**Interpretation narrates** structured evidence.  
**LLM must never invent astronomical facts.**

---

## 27. Current AI usage

**NO** for primary Yıldızname / Birth Chart reading.

Primary path is **LOCAL** catalogue + generators.  
AI only if user opens OR conversation (secondary).

---

## 28–31. Genericity, users, day, timezone

- Catalogue tones (3) + karmic themes (6) → **templated risk (P2)**; discovery overlay reduces sameness when history exists.
- First vs returning: insufficient themes vs recurring lines — tested.
- Midnight: local calendar day rolls; reading regenerates; no frozen leaf.
- Timezone: **device local** `DateTime.now()` — no birthplace TZ.

---

## 32. Safety

No Yıldızname-specific safety preflight (unlike Tarot).  
Copy leans symbolic/non-verdict.  
Global OR safety may catch chat follow-ups.  
**Gap (P2):** no dedicated high-risk claim filter on archive corpus.

---

## 33. Monetization

| | |
|--|--|
| Free | **YES** |
| Premium gate | **NO** |
| Gem charge for reading | **NO** |
| Gem capsule in header | Display / shop nav only |

---

## 34. Feature distinction

| Feature | Current job |
|---------|-------------|
| **Yıldızname** | Personal symbolic **archive / story path** (day chapters + optional birth leaf) |
| **Astrology** | Daily sun-sign **horoscope** reading (engine/prompt wired) |
| **Birth Chart** | Nested **identity + sun-sign chart leaf** under Yıldızname |

**Overlap:** both use sun signs + discovery; confusion risk if Yıldızname gains full natal without clear product split (**P1 product positioning**).

---

## 35–36. Tests & baseline

| Suite | Pass | Skip | Fail |
|-------|------|------|------|
| `test/features/star_map/` | **26** | 0 | 0 |
| `test/features/birth_chart/` | **30** | 0 | 0 |
| `test/yildizname_honesty_p0_test.dart` | **4** | 0 | 0 |
| Combined | **60** | 0 | 0 |

Coverage present: domain, honesty, personalization, layout, locale, cities, persistence reopen, connected memory.  

**Missing / thin:** E2E paid flow, red-team abandon races, frozen artifact reopen, favorite hash stability across process, owner isolation for `birth_chart_latest`, Evidence Acquisition Loop, ephemeris contract tests.

| Analyze (full) | |
|----------------|--|
| Errors | **0** |
| Warnings | **0** |
| Infos | **202** |

Feature-scoped analyze (`star_map` + `birth_chart`): no issues.

---

## 38. Component verdicts

| Component | Verdict |
|-----------|---------|
| `ChartCalculationPort` | **KEEP** |
| `NatalChartCalculator` | **KEEP BUT HARDEN** (honest sun-only) until replaced behind port |
| `StarMapReadingService` | **KEEP BUT HARDEN** (daily seed) |
| `StarMapCopy` / ArchiveBeats / Story | **KEEP BUT HARDEN** (catalogue quality) |
| `StarMapPersonalization` | **KEEP** |
| `BirthProfile` + city catalogue | **KEEP** |
| Current hub / result UI | **KEEP** (visual later) |
| Degree/house placeholders | **KEEP BUT HARDEN** (never surface without fidelity) |
| Favorite `Object.hash` id | **REPLACE** (stable content hash) |
| QualityLoopGate as “evidence loop” | **KEEP** telemetry; **FUTURE** real loop |
| Full natal empty lists | **FUTURE** via ephemeris |
| Dead legacy home discover wiring | **DELETE / QUARANTINE** when safe |

---

## Top product gaps

| Sev | Gap |
|-----|-----|
| **P0** | None proven as live honesty break (sun-only + copy gates hold) |
| **P1** | No frozen reading artifact; favorite `Object.hash` process stability; birth chart key lacks owner binding; product confusion vs Astrology if natal arrives without positioning |
| **P2** | Catalogue templating; no feature safety filter; locale affects favorite id; timezone = device only |
| **P3** | Internal “karmic” code keys; settings schema leftover `astrology_birth_chart` |

---

## Target architecture (proposed)

1. **Birth Evidence** — date / time known? / place / coords  
2. **Evidence Completeness** — decide reduced vs full scope  
3. **Astronomical Calculation** — `ChartCalculationPort` → ephemeris  
4. **Structured Natal Evidence** — typed placements (no prose facts)  
5. **Interpretation Engine** — narrate evidence only  
6. **Memory / History** — frozen artifacts + discovery themes  
7. **Quality Gate** — completeness + claim safety  
8. **Narrative** — archive voice (local first; LLM optional later)  
9. **Result Artifact** — immutable reopen contract  

---

## Proposed Yıldızname phases

| Phase | Focus |
|-------|--------|
| **1** | Product constitution + honesty/spec freeze (sun vs natal vs Astrology) |
| **2** | Acceptance harness before engine (fidelity matrix, reopen, owner) |
| **3** | Evidence model + completeness + Acquisition Loop (ask/reduce) |
| **4** | Calculation port + real ephemeris seam (no UI rewrite) |
| **5** | Structured evidence → interpretation (no LLM sky math) |
| **6** | Frozen artifacts + favorite identity + history reopen |
| **7** | Visual craftsmanship pass (keep sanctuary language) |
| **8** | E2E ritual + OR/share/privacy |
| **9** | Destructive red-team |
| **10** | Full-app regression / Yıldızname complete gate |

---

## File safety

| Item | Value |
|------|--------|
| Production files | **0** |
| Test files | **0** |
| Doc files | this file |
| Goldens / backend | untouched |
| Unrelated dirt | preserved |
| reset/clean/stash/restore/merge | **NO** |
| release/ios-1.0 / Build 4 | untouched |

---

## PHASE 0 — PASS

Next: Phase 1 — product constitution / acceptance harness design (no ephemeris yet).

STOP.
