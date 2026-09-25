# YILDIZNAME Phase 5 — Result Contract

**Status:** FROZEN  
**Schema name:** `oracly_yildizname_narrative_v1`  
**additionalProperties:** false

## Result shape

| Field | Type | Notes |
|-------|------|-------|
| `contractVersion` | int | Must be 1 |
| `languageCode` | `tr` \| `en` \| `ru` | Must match request |
| `scope` | `legacy` \| `reduced` \| `full` | Must match request |
| `summary` | `{ text, factRefs[], themeRefs[] }` | Evidence-bearing |
| `sections` | array | Bounded; each section evidence-bearing |
| `reflectionPrompt` | string | Bounded |
| `closingMessage` | string | Bounded |

## Section

| Field | Type |
|-------|------|
| `kind` | enum (below) |
| `text` | string (bounded) |
| `factRefs` | string[] |
| `themeRefs` | string[] |

### Allowed kinds

- `core_identity`
- `emotional_world`
- `mind_and_expression`
- `relationships_and_values`
- `drive_and_growth`
- `angles_and_houses` — **full scope only**
- `patterns_and_tensions`
- `strengths_and_resources`
- `archive_echo` — only when request themes exist
- `practical_reflection`

## Fact refs (request)

Examples: `placement.sun`, `placement.moon`, `angle.ascendant`, `angle.midheaven`, `house.7`, `aspect.sun.moon.conjunction`, `balance.elements`, `balance.modalities`.

Every result `factRef` must exist on the request. Unknown → FAIL.

## Theme refs

`theme.<n>` or stable label refs from request only. Empty themes → empty themeRefs; no fake recurrence.

## Placement fact (provider-safe)

| Scope | Fields |
|-------|--------|
| full (exact) | factRef, body, sign, degreeWithinSign, retrograde?, house, certainty |
| reduced (intervalStable) | factRef, body, sign, certainty — **no** degree/house/retrograde |
| ambiguous | omitted (no selected sign) |

**No raw 0–360 longitude. No birth data.**

## Client revalidation

`YildiznameResultParser` + `YildiznameQualityValidator` re-validate every provider map. Backend schema alone is insufficient.

## Length bands

Legacy shorter · Reduced medium · Full deep-but-readable. All fields bounded in schema.
