# YILDIZNAME Phase 4 — Engine Selection

**Status:** Production astronomy engine freeze  
**REAL PROVIDER CALLS:** 0

## Selected packages

| Package | Version | License | Role |
|---------|---------|---------|------|
| `astronomia` | **1.1.1** | MIT | Sun/Moon/planets, sidereal, nutation/obliquity |
| `timezone` | **0.11.1** | BSD-2-Clause | IANA historical TZ (`latest_all`) |

Pinned exactly in `pubspec.yaml` / `pubspec.lock` for determinism.

`flutter_local_notifications` upgraded to **22.3.1** solely to allow `timezone 0.11.1`.

## Why not Swiss Ephemeris

Swiss Ephemeris (and bindings such as `swisseph` / `sweph` / packages embedding its data) require a **commercial license** for closed-source distribution. ORACLY does not currently hold that license.

A package claiming MIT while embedding Swiss Ephemeris does **not** waive the underlying Swiss license.

Phase 4 therefore uses:

- **astronomia** — Dart port of Meeus *Astronomical Algorithms* (VSOP87 / lunar series), pure Dart, no native code, no network, datasets bundled as source constants.

## Audit (astronomia 1.1.1)

- License: MIT (Daniel Vilela, 2026)
- Direct runtime dependencies: none
- Network / downloads: none found
- Native code: none
- Datasets: source constants (VSOP87 terms, lunar series, Pluto Ch.37)

## Product conventions

| Choice | Value |
|--------|-------|
| Zodiac | Tropical |
| Coordinates | Geocentric apparent ecliptic longitude of date |
| Houses | **Whole Sign** (product choice — not claimed as the only correct system) |
| Engine id | `oracly.astronomia` |
| Calculation version | `yildizname-natal-v1` |
| Supported civil range | 1900-01-01 … today (UTC calendar) |

## Future option

If ORACLY obtains a valid commercial Swiss Ephemeris license, a new adapter may be added behind `AstronomicalEphemerisPort` without rewriting evidence routing. Until then: **no Swiss dependency in the repository**.
