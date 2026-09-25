# YILDIZNAME Phase 5 — Narrative Engine

**Status:** IMPLEMENTED / FROZEN (feature flag default **false**)  
**HEAD gate:** Phase 4.1 frozen → Phase 5 narrative quality engine  
**Owner:** Yıldızname Narrative V1 (`lib/features/star_map/narrative/`)

## Purpose

Turn verified structured natal evidence into a professional, grounded, safe narrative.

```
Birth Evidence → Deterministic Astronomy → NatalChartEvidence
  → Safe Narrative Request → Writer → Structured Result
  → Evidence / Safety / Prose Quality → Accepted Narrative
```

## Non-goals (later phases)

| Gap | Owner |
|-----|-------|
| Immutable artifacts / history / durable ids | Phase 6 |
| Result visual architecture / scope chrome | Phase 7 |
| Live user-path activation | Phase 8 |
| Destructive red-team | Phase 9 |
| Full-app YILDIZNAME COMPLETE | Phase 10 |

## Feature flag

| Key | Default | Effect |
|-----|---------|--------|
| `yildizname_narrative_v1` | **false** | Remote true enables Narrative V1 for future Phase 8 wiring; false keeps `StarMapReadingService` local archive |

Failed V1 attempts **never** fall back to canned StarMapCopy success in the same request.

## Versions

| Constant | Value |
|----------|-------|
| Narrative version | 1 |
| Serializer version | 1 |
| Contract version | 1 |
| Result contract version | 1 |
| Mode | `natal_narrative_v1` |
| Policy | `yildizname_policy_v1` |
| Operation | `yildizname_reading` |
| Writer model (locked) | `gpt-5.6-sol` |
| Reasoning | `none` |
| Max provider attempts | 2 (`:yv1:a1` / `:yv1:a2`) |

## No-astronomy-in-writer

The writer receives authoritative facts only. It must never infer Moon / Asc / houses / aspects / degrees from birth inputs. Raw birth data, coordinates, timezone, and owner ids are **forbidden** in the provider payload.

## Scopes

| Fidelity | Scope | Content |
|----------|-------|---------|
| `tropicalSunSign` | `legacy` | Sun identity; modest disclosure |
| `reducedNatal` | `reduced` | intervalStable signs; no Asc/MC/houses/degrees |
| `fullNatalEphemeris` | `full` | placements + angles + Whole Sign houses + aspects + balances |

## Evidence source of truth

`NatalChartEvidence` only — not legacy `BirthChart.sun/planets/houses` presentation mirrors. Placeholder `degree:0` / `house:0` never enter Narrative V1.

## Discovery themes

At most 3 `PersonalDiscoveryProfile.observedRecurringLabels`. Themes may affect emphasis; they must **not** mutate astronomical facts (fingerprint invariance tested).

## Architecture

```
lib/features/star_map/narrative/
  request/   — factory, facts, policy, fingerprint, wire
  result/    — structured result + strict parser
  quality/   — grounding, safety, prose, coverage
  live/      — flag gate, attempt, cache, service
```

Backend: `narrative-yildizname-*.ts` + `narrative-yildizname-attempt.ts`.

## Rollback

Flag false → existing StarMapReadingService / StarMapCopy path untouched.
