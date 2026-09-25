# YILDIZNAME Phase 1 — Truth Matrix (machine-testable contract)

**START HEAD:** `29543f270254dafe9b215cb887ac2fb3135aa153`  
Companion: [`YILDIZNAME_PHASE1_PRODUCT_CONSTITUTION.md`](./YILDIZNAME_PHASE1_PRODUCT_CONSTITUTION.md)

This matrix is the Phase 2 harness source of truth. Symbols:

- `✓` allowed under stated fidelity/certainty  
- `✗` forbidden  
- `I` interval-stable only (unknown time + place)  
- `A` ambiguous if varies in interval (must not pick)  
- `L` legacy/symbolic only (`tropicalSunSign`) — must be labeled  

---

## 1. Evidence × completeness

| Code | Completeness | Evidence |
|------|--------------|----------|
| E0 | `missingDate` | no birth date |
| E1 | `dateOnly` | date |
| E2 | `dateAndPlaceNoTime` | date + place/coords (+ resolvable TZ) |
| E3 | `dateAndTimeNoPlace` | date + local time text, no place/TZ |
| E4 | `full` | date + time + place + resolved TZ → UTC |

---

## 2. Fidelity

| Fidelity | When |
|----------|------|
| `tropicalSunSign` | Legacy live calculator; date → sun sign |
| `reducedNatal` | Future: incomplete evidence / interval-safe subset |
| `fullNatalEphemeris` | Future: E4 + verified engine |

Current production enum has `tropicalSunSign` + `fullNatalEphemeris` only. `reducedNatal` is conceptual until Phase 4.

---

## 3. Certainty

| Token | Rule |
|-------|------|
| `exact` | Verified exact UTC birth instant |
| `intervalStable` | Invariant across unknown-time day interval |
| `ambiguous` | Changes in interval — withhold choice |
| `unavailable` | Evidence or engine insufficient |
| `unsupported` | Engine capability gap |

---

## 4. Evidence × allowed result layers

| Layer | E0 | E1 | E2 | E3 | E4+engine |
|-------|----|----|----|----|-----------|
| Onboarding / honesty copy | ✓ | ✓ | ✓ | ✓ | ✓ |
| Sun sign (legacy date table) | ✗ | L | L | L | ✓ `exact` preferred |
| Sun longitude / degree | ✗ | ✗ | I/A | ✗ | ✓ |
| Moon | ✗ | ✗ | I/A | ✗ | ✓ |
| Mercury–Mars (personal) | ✗ | ✗ | I/A | ✗ | ✓ |
| Jupiter–Pluto (outer) | ✗ | ✗ | I/A | ✗ | ✓ |
| Ascendant | ✗ | ✗ | ✗ | ✗ | ✓ |
| MC | ✗ | ✗ | ✗ | ✗ | ✓ |
| Houses | ✗ | ✗ | ✗ | ✗ | ✓ |
| Aspects | ✗ | ✗ | I rare | ✗ | ✓ |
| Element/modality (from sun) | ✗ | L | L | L | ✓ from placements |
| Natal themes (reduced) | ✗ | L | L | L* | ✓ |
| Natal themes (full) | ✗ | ✗ | ✗ | ✗ | ✓ |
| Archive / discovery narrative | ✓ empty | ✓ | ✓ | ✓ | ✓ |
| Daily symbolic leaf | ✓ | ✓ | ✓ | ✓ | ✓ |
| Transits / present sky | ✗ Yıldızname | — owned by **Astrology** | | | |

\* E3 may keep legacy sun narrative only; must not claim full natal.

---

## 5. Unknown-time policy

| Rule | Value |
|------|-------|
| Default time (12:00 / 00:00 / sunrise / now) | **FORBIDDEN** as factual instant |
| Noon chart | **FORBIDDEN** |
| Interval evaluation | **REQUIRED** when E2 |
| Ascendant / houses / MC | **UNAVAILABLE** |
| Re-ask after `timeUnknownConfirmed` | **NO** (edit profile only) |
| Product outcome | **SUCCESS** (reduced scope) |

---

## 6. Location / timezone

| Input | Required for E4 | Notes |
|-------|-----------------|-------|
| Place display name | yes | |
| Lat / lon | yes | |
| `timezoneId` | yes | |
| Historical offset | yes | via TZ DB |
| Device timezone as birth TZ | **FORBIDDEN** | |
| Silent “Türkiye” assumption | **FORBIDDEN** | |

E3 (time without place): full natal **unavailable**; ask place once.

---

## 7. Artifact behavior

| Event | LIVE TODAY | SAVED ARTIFACT |
|-------|------------|----------------|
| New calendar day | may change | unchanged |
| Locale change | may change presentation seed of live leaf | narrative frozen |
| Feature flag / model change | may affect new live | unchanged |
| PersonalDiscovery update | may affect live narrative | unchanged |
| Reopen | rebuild live | **exact stored** |
| Durable id | n/a | **not** `Object.hash` |

---

## 8. Owner / privacy / OR / share

| Rule | Contract |
|------|----------|
| Owner scope | Required for birth + artifacts when authenticated |
| Account A → B | **FORBIDDEN** |
| OR: raw lat/lon | **FORBIDDEN** by default |
| OR: verified placements + fidelity | allowed |
| Share: birth timestamp / coords / JSON | **FORBIDDEN** by default |
| Share: insight text | allowed |

---

## 9. Safety / karmic

| Claim type | Status |
|------------|--------|
| Death / lifespan | FORBIDDEN |
| Medical / pregnancy certainty | FORBIDDEN |
| Legal / financial guarantee | FORBIDDEN |
| Guaranteed soulmate / exact future event | FORBIDDEN |
| Fixed unavoidable fate | FORBIDDEN |
| “Karmic” as past-life fact | FORBIDDEN |
| “Karmic” as reflective metaphor | allowed if clearly symbolic |

---

## 10. Product distinction (one line)

| Product | Owns |
|---------|------|
| **Yıldızname** | Birth + natal identity + archive |
| **Astrology** | Present sky + timing + transits |
| **Birth Chart** | Evidence + calculation subjourney inside Yıldızname |

---

## 11. Legacy migration flags

| Legacy item | Treatment |
|-------------|-----------|
| `birth_chart_latest` | Preserve; tag fidelity |
| Date-only sun | `tropicalSunSign` |
| `sun.degree = 0` / `sun.house = 0` | Internal placeholder — never user claim |
| Favorites with `Object.hash` | Migrate to durable id later; do not treat as golden identity |

---

## 12. Phase 2 fail-fast checklist

Harness fails when any of:

1. Invented Moon / Rising / house / aspect  
2. Silent default birth time  
3. Silent assumed place/TZ  
4. Artifact regenerates on reopen  
5. Owner leakage  
6. Fabricated history / memory  
7. Yıldızname presents as Astrology transit surface  
8. Fatalistic / safety-forbidden claim  
9. Locale mutates stored **facts**  
10. Reduced scope treated as hard failure  
11. Discovery themes mutate sky facts  
12. LLM used as sky calculator  

---

## PHASE 1 TRUTH MATRIX — FROZEN

STOP.
