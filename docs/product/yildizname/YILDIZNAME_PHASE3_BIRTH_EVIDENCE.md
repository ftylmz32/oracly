# YILDIZNAME Phase 3 — Birth Evidence

**Status:** PASS / FROZEN (when gates green)  
**Production changes:** evidence layer + owner-safe persistence + acquisition loop  
**Real provider calls:** 0  
**Ephemeris:** NOT in this phase

## Purpose

First production layer of professional Yıldızname:

USER BIRTH EVIDENCE → COMPLETENESS → ACQUISITION PLAN → OWNER-SAFE PERSISTENCE → HONEST REDUCED SCOPE

## Production types

| Type | Role |
|------|------|
| `BirthEvidence` | Typed evidence view |
| `BirthEvidenceCompleteness` | missingDate / dateOnly / dateAndPlaceNoTime / dateAndTimeNoPlace / full |
| `BirthEvidenceClassifier` | Deterministic E0–E4 |
| `BirthEvidenceAcquisitionPlan` | Next ask (date → time knowledge → time → place → none) |
| `BirthTimezoneStatus` | missing / resolved / failed |

**Phase 3 `resolved`** = stable IANA `timezoneId` for place.  
**Not** historical UTC offset (Phase 4).

## E0–E4 mapping

| Completeness | Phase 2 | Meaning |
|--------------|---------|---------|
| missingDate | E0 | No date |
| dateOnly | E1 | Date only |
| dateAndPlaceNoTime | E2 | Date + place/TZ, time unknown |
| dateAndTimeNoPlace | E3 | Date + time, place unresolved |
| full | E4 | Evidence complete |

**E4 ≠ full natal.** `NatalChartCalculator` remains `tropicalSunSign`.

## Place validity

E2/E4 require: non-empty place + lat + lon + timezoneId + status resolved.  
String-only place is not full evidence. No Türkiye assumption when place missing.

## Acquisition (ask-once)

- Persisted `birthTimeKnown == false` → do not re-ask time
- Persisted `birthPlaceUnknownConfirmed == true` → do not auto-ask place
- Manual Edit still exposes all fields
- Submit without place → reduced continue (`birthPlaceUnknownConfirmed = true`)
- Selecting place clears unknown flag and stamps city id / coords / TZ

## Scope disclosure

- E1–E3: reduced-scope copy
- E4 (pre-Phase 4): evidence saved; sky math not yet used in result

## Remaining Phase 4 gaps

Real ephemeris · structured planets/houses/aspects · historical UTC · Ascendant/MC
