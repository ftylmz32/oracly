# YILDIZNAME Phase 2 — Acceptance Harness

**Status:** PASS / FROZEN  
**Branch:** `fix/final-product-remediation-20260922`  
**Production behavior changed:** 0  
**Real provider calls:** 0

## Purpose

Phase 2 freezes an executable **TEST-ONLY** truth oracle before Birth Evidence, ephemeris, interpretation, and artifact work.

It encodes Phase 1 contracts as acceptance tests so later phases can adapt production types without rewriting the constitution.

## What Phase 2 is not

- Not a real ephemeris
- Not Evidence Acquisition UI
- Not production safety gate
- Not artifact repository
- Not astronomy library selection

## Root

```
test/features/yildizname_contract/
  truth/          # contract enums, oracle, validators, fingerprint, safety
  fixtures/       # evidence, candidates, artifacts, safety, manifest
  phase2_*_test.dart
```

## Architecture

| Layer | Role |
|-------|------|
| `ContractEvidenceInput` + `YildiznameEvidenceClassifier` | Deterministic E0–E4 |
| `YildiznameFactMatrix` | Allowed facts × certainty × state |
| `YildiznameTruthOracle` | Candidate chart acceptance |
| `YildiznameContractAssertions` | Owner, reopen, groundedness, memory |
| `ContractGateResult` | `pass` / `fail` / `knownGap` |
| `YildiznameAstronomicalFingerprint` | Locale/theme-invariant fact digest |
| `AstronomicalFixtureManifest` | Future fixture categories (`PENDING_AUTHORITY`) |

All types are **spec oracle** types. Production may later map onto them; they must not leak into `lib/`.

## Evidence states

| State | Meaning |
|-------|---------|
| E0 | No birth date |
| E1 | Date only |
| E2 | Date + place, time unknown |
| E3 | Date + time, place/TZ unresolved |
| E4 | Date + time + place + resolved TZ |

**E4 ≠ calculation supported.** E4 + no engine → `unsupported` / `unavailable`, never invented facts.

## Reduced scope

Honest reduced results (E1/E2 with disclosure + unavailable layers) are **valid SUCCESS**. Full natal is never required for pass.

## Known gaps

See `YILDIZNAME_PHASE2_KNOWN_GAPS.md`. Gaps use `ContractGateResult.knownGap` so Phase 2 stays green while documenting non-compliance of current production.

## Future adapter strategy

1. Phase 3+ introduce production evidence / owner models.
2. Adapter maps production → `Contract*` types.
3. Same Phase 2 tests run against adapters (or shared fixtures).
4. Astronomical goldens stay `PENDING_AUTHORITY` until Phase 4 cites an authoritative source.

## Baseline regressions

Phase 2 also re-asserts current honesty via production imports:

- `NatalChartCalculator` → `tropicalSunSign`, no Moon/Rising/houses/aspects
- Registry: Yıldızname `/star-map`, separate from Astrology

## Docs sibling

- Phase 0 forensic audit
- Phase 1 constitution
- This harness doc
- Known gaps ledger
