# Signature Spreads — Phase 6 Seam Audit

**Phase:** 6G (Crossroads internal Narrative) · **Status:** DOCUMENTED · **Live Crossroads:** NOT READY  
**Date:** 2026-09-25  
**Branch:** `fix/final-product-remediation-20260922`

This document states what Phase 6 must solve before `signature.crossroads` can become a live Narrative V2 spread.  
Phase 6G wires **internal** Evidence + history + serializer for Crossroads. **It does not make Crossroads publicly live.**

---

## Current Capability Matrix (locked · Phase 6G)

| Capability | Quick Insight | Timeline | Deep Field | Crossroads |
|---|---|---|---|---|
| Runtime | YES | YES | YES | YES |
| Persistence | YES | YES | YES | YES |
| Localization | YES | YES | YES | YES |
| Structural projection | YES | YES | YES | YES |
| Phase 3 evidence builder | YES | YES | YES | **YES (internal Signature path)** |
| Phase 3 consumes Signature edges | N/A (classical global edges) | N/A | N/A | **YES** |
| Phase 4 history enricher | YES | YES | YES | **YES (internal)** |
| Live Narrative V2 | YES (flag) | YES (flag) | YES (flag) | **NO** |
| Live picker | YES | YES | YES | **NO** |

---

## Phase 6 seams

| ID | Seam | Classification | Notes |
|---|---|---|---|
| A | Generalized Narrative evidence input must resolve Signature spreads without pretending all spreads are Classical | **DONE (6A/6G)** | `SignatureNarrativeSpreadResolver` + builder injection |
| B | Audited edge-provider seam for relationship scorer to consume Phase 5 edges without copying scorer / mutating global state / losing Classical parity | **DONE (6A/6G)** | `SignatureNarrativeEdgeProvider` + dispatch |
| C | Crossroads edge graph must produce real deterministic relationship evidence | **DONE (6G)** | Existing scorer/selector; edges by reference; empty when unsupported |
| D | Signature history normalizer / source adapter for `signature.crossroads` | **DONE (6B/6G)** | `SignatureHistorySpreadNormalizer` |
| E | Recurrence: same-spread-alone must **not** authorize recurrence (`forbidSameSpreadAloneAuth=true`) | **BLOCKER** before live Crossroads | Preserve forever for launch catalog |
| F | H7 transitive physical identity remains intact | **MAJOR** before live V2 migration | Do not weaken Phase 4 identity firewalls |
| G | H19 deterministic ordering remains intact | **MAJOR** before live V2 migration | Exact-tie representative determinism |
| H | Privacy / owner / source-existence firewalls remain intact | **MAJOR** before live V2 migration | Including `privacyBlocked` short-circuit |
| I | Current 1/3/5 classical Narrative requests remain byte/semantic compatible | **BLOCKER** before live Crossroads | Classical shadow parity must not regress |
| J | Crossroads relationship `QuestionKind` remains unsupported | **BLOCKER** before live Crossroads | No silent remap to open/decision |
| K | Live picker remains disabled until Narrative V2 + result pipeline + visual gates are ready | **BLOCKER** before live Crossroads | `offeredInLivePicker=false` through Phase 7/8 |
| L | No release-readiness claim solely from Phase 5/6G | **MAJOR** before live V2 migration | Internal support ≠ App Store ready for Crossroads |

### Counts

| Class | Count |
|---|---|
| **DONE** (internal) | **4** (A–D) |
| **BLOCKER** before live Crossroads | **4** (E, I–K) |
| **MAJOR** before live V2 migration | **4** (F–H, L) |

### Open Phase 5 blockers / majors

| Open Phase 5 BLOCKERS | **0** (5E shadow complete; Crossroads live deferred) |
| Open Phase 5 MAJORS | **0** |

---

## Explicit non-claims

- Phase 6G does **not** wire live Narrative V2 for Crossroads.
- Phase 6G does **not** enable Crossroads in entry / ritual / table pickers.
- Phase 6G does **not** add Crossroads to `NarrativeTarotLiveGate` / live spreads.
- Phase 6G does **not** insert Crossroads edges into `kAuthoritativePositionEdges`.
- Phase 6G does **not** claim public release readiness for Crossroads.

---

## Next

**Phase 6H** — Independent Phase 6 final audit.  
Crossroads public exposure remains gated by Phase 7 + Phase 8.
