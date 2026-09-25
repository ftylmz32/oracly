# YILDIZNAME Phase 4 — Astronomical Fixtures

**Invented authoritative values:** NO  
**Engine under test:** `oracly.astronomia` / astronomia 1.1.1  
**Phase 4.1:** independent Asc/MC + retrograde numeric freeze

## J2000 planetary longitudes

| Field | Value |
|-------|-------|
| Instant | 2000-01-01 12:00:00 UT (JD 2451545.0) |
| Source | NASA/JPL Horizons API `ssd.jpl.nasa.gov` |
| Query | OBSERVER, CENTER=`500@399`, QUANTITIES=`31` (ObsEcLon/ObsEcLat), ANG_FORMAT=DEG |
| Retrieved | 2026-09-25 |
| Convention | Geocentric ecliptic longitude of date (degrees) |

Frozen expected ObsEcLon:

| Body | Degrees |
|------|---------|
| Sun | 280.3689092 |
| Moon | 223.3237860 |
| Mercury | 271.8892699 |
| Venus | 241.5657794 |
| Mars | 327.9632921 |
| Jupiter | 25.2530685 |
| Saturn | 40.3956366 |
| Uranus | 314.8091680 |
| Neptune | 303.1930007 |
| Pluto | 251.4547644 |

## Meeus worked examples (algorithm regression)

| Case | Source | Expected |
|------|--------|----------|
| Sun 1992-10-13.0 TD apparent | Meeus AA Ch.25 | 199°54′32″ |
| Moon 1992-04-12.0 TD mean lon | Meeus AA Ch.47 / PyMeeus | 133.162655° |

## Phase 4.1 — Ascendant numeric fixtures

### ASC fixture 1 — Chicago (preferred)

| Field | Value |
|-------|-------|
| Source | Phase 4.1 independent validation gate preferred fixture (public review); independent astronomy-engine class |
| Retrieved / published | 2026-09-25 (gate) |
| UTC | 1990-07-14T08:20:00Z |
| Latitude | 41.85° |
| Longitude | −87.65° |
| Expected Asc | 82.562° |
| Tolerance | ≤ 0.10° |

### ASC fixture 2 — São Paulo (southern)

| Field | Value |
|-------|-------|
| Source | [J-Kit — How a birth chart is calculated](https://jkit.tools/en/articles/how-a-birth-chart-is-calculated) (astronomy-engine / VSOP87) |
| Published | 2026-07-09 |
| Retrieved | 2026-09-25 |
| UTC | 2000-07-15T12:30:00Z (local 09:30, UTC−3) |
| Latitude | −23.55° |
| Longitude | −46.63° |
| RAMC / LST | 74.53° |
| Expected Asc | 159.44° (9°26′ Virgo) |
| Expected MC | 75.76° (15°45′ Gemini) |
| Tolerance | ≤ 0.10° |

### Enschede Asc cross-check (RadixPro)

| Field | Value |
|-------|-------|
| Source | [RadixPro — The ascendant](https://radixpro.com/a4a-start/the-ascendant/) |
| Retrieved | 2026-09-25 |
| UTC | 2016-11-02T21:17:30Z |
| Latitude | 52°13′ N (= 52.2166…°) |
| Longitude | 6.9° E |
| RAMC | 8.8485279795° |
| Expected Asc | 123.5079833456672618° |
| Tolerance | ≤ 0.10° |

## Phase 4.1 — Midheaven numeric fixtures

### MC fixture 1 — Enschede (RadixPro)

| Field | Value |
|-------|-------|
| Source | [RadixPro — Medium Coeli](https://radixpro.com/a4a-start/medium-coeli/) |
| Retrieved | 2026-09-25 |
| UTC | 2016-11-02T21:17:30Z |
| Longitude | 6.9° E |
| ARMC / RAMC | 8.8485279795° |
| Expected tropical MC | 9.62989868323° |
| Tolerance | ≤ 0.10° |

### MC fixture 2 — São Paulo (J-Kit)

Same instant/coordinates as ASC fixture 2. Expected MC **75.76°**. Tolerance ≤ 0.10°.

## Formula provenance (supplementary — does not replace numeric fixtures)

### Midheaven (Meeus AA Ch.13 / RadixPro)

```
MC = atan2( sin(RAMC), cos(RAMC) · cos(ε) )
```

with quadrant normalization to `[0, 360)`.

### Ascendant (Meeus AA Ch.13 / Wikipedia / RadixPro / J-Kit)

```
Asc = atan2( cos(RAMC), −(sin(RAMC)·cos(ε) + tan(φ)·sin(ε)) )
```

with eastern-intersection / hemisphere correction via `atan2`.

## Sunrise sanity (supplementary)

| Field | Value |
|-------|-------|
| Instant | 2000-03-20T06:07:00Z |
| Location | Greenwich φ=51.5° λ=0° |
| Invariant | Ascendant ≈ Sun longitude near geometric sunrise |
| Tolerance | ≤ 2.0° (wider; anti-Descendant-flip check) |

## Phase 4.1 — Retrograde fixtures (Horizons frozen)

Source: NASA/JPL Horizons API · OBSERVER · QUANTITIES=31 · CENTER=`500@399` · STEP=12h · Retrieved **2026-09-25**. No runtime network.

### Mercury retrograde — 2023-08-30 12:00 UT

| T−12h | T | T+12h | Expected motion | Detector |
|-------|---|-------|-----------------|----------|
| 169.9930352° | 169.6801019° | 169.3447391° | signed < 0 | `true` |

### Mercury direct — 2024-01-15 12:00 UT

| T−12h | T | T+12h | Expected motion | Detector |
|-------|---|-------|-----------------|----------|
| 270.9702279° | 271.5339956° | 272.1072105° | signed > 0 | `false` |

### Jupiter retrograde (outer) — 2023-09-15 12:00 UT

| T−12h | T | T+12h | Expected motion | Detector |
|-------|---|-------|-----------------|----------|
| 45.4000919° | 45.3822115° | 45.3634975° | signed < 0 | `true` |

### Jupiter direct — 2024-03-01 12:00 UT

| T−12h | T | T+12h | Expected motion | Detector |
|-------|---|-------|-----------------|----------|
| 41.3141715° | 41.3997110° | 41.4857137° | signed > 0 | `false` |

Wrap-around (359°↔0°) uses a deterministic test fake to prove shortest-angle unwrap; R/D truth cases remain Horizons-grounded.

## Timezone fixtures

| Zone | Local | Expected UTC |
|------|-------|--------------|
| Europe/Istanbul | 2010-01-15 12:00 | 2010-01-15 10:00 (historical +2) |
| Europe/Berlin | 2015-07-01 12:00 | 10:00 (CEST) |
| Europe/London | 2015-07-01 12:00 | 11:00 (BST) |
| America/New_York | 2015-07-01 12:00 | 16:00 (EDT) |
| America/New_York | 2006-04-02 02:30 | nonexistent |
| America/New_York | 2006-10-29 01:30 | ambiguous |

## Tolerances

Sun/planets ≤ 0.05° · Moon ≤ 0.10° · Asc/MC independent numeric ≤ 0.10° (**do not loosen**)

## Notes

- Expected Asc/MC/retrograde values are **not** generated by `AstronomiaEphemerisAdapter`, `AngleCalculator`, or `RetrogradeDetector`.
- Package upstream tests are **not** treated as authoritative ORACLY fixtures.
- Swiss Ephemeris numerical sites may be used as supplemental cross-checks; Swiss code/data are **not** dependencies.
- Production dependency policy unchanged (astronomia MIT · timezone BSD-2-Clause).
