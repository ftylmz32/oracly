# YILDIZNAME Phase 4 — Astronomical Fixtures

**Invented authoritative values:** NO  
**Engine under test:** `oracly.astronomia` / astronomia 1.1.1

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

Sun/planets ≤ 0.05° · Moon ≤ 0.10° · Asc/MC self-consistency + Meeus formula ≤ 0.10°

## Notes

- Package upstream tests are **not** treated as authoritative ORACLY fixtures.
- Swiss Ephemeris numerical sites may be used as supplemental cross-checks; Swiss code/data are **not** dependencies.
