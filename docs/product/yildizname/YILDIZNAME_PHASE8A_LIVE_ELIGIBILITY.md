# Yıldızname Phase 8A — Live Narrative Eligibility Plan

**Status:** PASS  
**Phase 8A frozen:** YES  
**Phase 8B ready:** YES  
**Branch:** `fix/final-product-remediation-20260922`  
**Base HEAD:** `a7fa382422f694dd680a9056b95f4e4372f33340`

**Phase 8A does NOT activate live Narrative for users.**

---

## Purpose

Before wiring Narrative V1 into a visible route, establish one truthful typed
decision boundary:

1. Is this current Yıldızname request eligible for Narrative V1?
2. What authoritative natal evidence is allowed?
3. What exact safe Narrative request would be sent?
4. Why must a request **not** be sent when evidence/owner/flag is insufficient?

No AI provider call. No hub/result navigation change. No artifact completion.

---

## Why Phase 8A exists

Phase 5 contract:

Birth Evidence → deterministic astronomy → `NatalChartEvidence` → safe
Narrative request → writer.

The writer must not become a sky calculator. Phase 8A freezes the **eligibility
preflight** so Phase 8B can orchestrate loading/invoke/persist without inventing
facts from legacy presentation mirrors.

---

## Safe activation subset (E0–E4)

| Evidence | Authoritative `NatalChartEvidence` | Plan (flag true + owner) |
|---|---|---|
| E0 no profile | none | `legacyLocal` |
| E1 date only / tropicalSunSign | null | `legacyLocal` |
| E2 date + place/TZ, unknown time | `reducedNatal` | `narrativeReduced` |
| E3 time but no valid place/TZ | null | `legacyLocal` |
| E4 exact time + place/TZ | `fullNatalEphemeris` | `narrativeFull` |

Ambiguous/nonexistent local time that deterministically degrades to reduced is
respected by the **actual** calculator fidelity — not by the user's input label.

**Not in this activation subset:** inventing a legacy-Narrative adapter from
`BirthChart.sun` / placeholder `degree: 0` / `house: 0`. That remains a future
deliberate product decision.

---

## Feature flag

`YildiznameNarrativeLiveGate` / `yildizname_narrative_v1` — **default false**.

Flag false → always `legacyLocal` (even with full evidence). No request. No
provider. Existing hub → legacy archive leaf path untouched.

---

## Owner requirement

Narrative-eligible evidence without a non-blank owner → `ownerUnavailable`.

No invented owners (`anonymous`, `guest`, `local`, device id). Owner stays
orchestration metadata and is **never** placed in the Narrative request or
provider payload. Canonical local authority remains
`UserLocalDataIsolation.ownerKey` (Phase 8B wiring).

---

## Stale / invalid evidence

Fail closed with `invalidEvidence` (no provider):

- chart fidelity ≠ evidence fidelity
- calculationVersion ≠ `AstronomicalProvenance.calcYildiznameNatalV1`
- evidenceFingerprint mismatch vs `EvidenceFingerprint.of(profile)`
- missing/blank evidence fingerprint metadata

No silent downgrade inside the request builder. No astronomy recompute inside
the pure plan builder.

---

## Request source of truth

Eligible plans build requests **only** through:

`YildiznameRequestFactory.fromEvidence(...)`

Themes:

1. verified same-owner Yıldızname artifact recurrence (`YildiznameArtifactMemory`)
2. Personal Discovery fill
3. max 3 via `YildiznameThemeMerge`

Personal Discovery never alters astronomical facts. Legacy artifacts never prove
Narrative recurrence.

---

## Fingerprints

| Kind | Source |
|---|---|
| Request | `YildiznameRequestFingerprint.of(request)` |
| Facts-only | `YildiznameRequestFingerprint.factsOnly(request)` |
| Evidence | `NatalChartEvidence.metadata.evidenceFingerprint` (orchestration only) |

PD theme changes may change the full request fingerprint; facts-only must stay
stable for identical astronomy.

### Semantic fingerprint policy (explicit deferral)

Phase 6 stores `semanticFingerprint` as a **caller-supplied** field. There is
no frozen production mapping from request fingerprint → semantic fingerprint
yet. Phase 8A therefore **does not** assign `semanticFingerprint`.

**Phase 8B persistence decision:** choose and freeze the authoritative mapping
(likely `YildiznameRequestFingerprint.of(request)`) at Narrative completion
time — do not guess here.

---

## Privacy firewall

Provider payload via `YildiznameWireContract.payload(request)` must contain no:

birth date/time/place · lat/lon · timezoneId · ownerId · artifactId ·
evidenceFingerprint · semanticFingerprint · raw BirthProfile JSON

---

## Implementation

| File | Role |
|---|---|
| `yildizname_live_plan.dart` | immutable typed plan + kinds |
| `yildizname_live_plan_builder.dart` | pure resolver |

No Riverpod in the pure builder. No route/UI/loading/error wiring in 8A.

---

## No-provider guarantee

Phase 8A core tests do not construct `YildiznameNarrativeLiveService` or
`OpenAiOraclyAiService`. Real provider calls: **0**.

---

## What Phase 8B owns

- authoritative local evidence refresh/load
- Narrative service invocation behind the flag
- loading / error / retry (`StarMapLoadingCinema` / `StarMapErrorState`)
- artifact completion + semantic fingerprint assignment
- canonical live presentation push
- route activation (still flag-gated)

Do not implement Phase 8B in this document’s commit.
