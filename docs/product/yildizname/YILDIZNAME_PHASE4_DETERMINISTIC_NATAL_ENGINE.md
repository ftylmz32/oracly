# YILDIZNAME Phase 4 — Deterministic Natal Engine

## Pipeline

Birth evidence → historical UTC instant → ephemeris → structured `NatalChartEvidence` → presentation adapter.

## UTC resolution

- IANA DB: `timezone` `latest_all` via `BirthTimezoneDatabase`
- Never `setLocalLocation` for birth math; never device TZ as birth TZ
- Civil clock fields interpreted in `profile.timezoneId`
- DST: collect plausible offsets → round-trip filter → exact / ambiguous / nonexistent
- Ambiguous → reduced natal (no arbitrary pick)
- Nonexistent → typed `NatalNonexistentLocalTimeException` (no clock shift)

## Ephemeris APIs (`astronomia` 1.1.1, public only)

| Body | API |
|------|-----|
| Sun | `solar.apparentVSOP87(earth, jde)` |
| Moon | `moonposition.position` + nutation Δψ |
| Mercury–Neptune | `elliptic.position` → `coord.eqToEcl` with true obliquity |
| Pluto | Ch.37 heliocentric → geocentric ecliptic + Δψ |
| Sidereal | `sidereal.apparent` |
| Obliquity | `nutation.meanObliquity` + `nutation.dEps` |

Convention: **geocentric tropical apparent ecliptic of date**. Longitude normalized to `[0,360)`.

## Ascendant / MC

Meeus AA Ch.13 with local apparent sidereal time and true obliquity. MC is independent of Whole Sign cusps.

## Whole Sign houses

Asc sign = House 1; following signs 2–12; cusp = 0° of each sign. Planet house = sign offset from Asc. **≠ Equal House.** MC house follows MC sign (not forced to 10).

## Retrograde

Finite difference Δ = 12h on apparent longitude; unwrap across 0/360. Sun/Moon: never labelled retrograde.

## Aspects

Major aspects only among Sun–Pluto using existing `AspectType` orbs. No Asc/MC aspects in Phase 4 baseline.

## E2 interval

Civil local day in explicit TZ; ≤5-minute samples. Sign emitted as `intervalStable` only if unchanged all day; else `ambiguous`. No longitude/degree/retrograde/houses/Asc/MC/aspects.

## Evidence routing

| Evidence | Fidelity |
|----------|----------|
| E1 / E3 | `tropicalSunSign` (legacy calculator) |
| E2 | `reducedNatal` |
| E4 exact | `fullNatalEphemeris` |
| E4 ambiguous | reduced |
| E4 nonexistent | typed failure |

## Tolerances

Sun/planets ≤ 0.05° · Moon ≤ 0.10° · Asc/MC ≤ 0.10° (vs authoritative fixtures).

## Provenance

Every structured fact carries engine id/version, `yildizname-natal-v1`, evidence fingerprint (SHA-256 over date/time/place/coords/tz — no owner/locale/narrative).
