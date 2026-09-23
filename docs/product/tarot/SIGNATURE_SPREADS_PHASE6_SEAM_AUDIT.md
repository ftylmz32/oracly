# Signature Spreads — Phase 6 Seam Audit

**Phase:** 5E (shadow integration) · **Status:** DOCUMENTED · **Live Crossroads:** NOT READY  
**Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`

This document states what Phase 6 must solve before `signature.crossroads` can become a live Narrative V2 spread.  
Phase 5E provides structural shadow evaluation only. **It does not make Crossroads live.**

---

## Current Capability Matrix (locked · Phase 5E)

| Capability | Quick Insight | Timeline | Deep Field | Crossroads |
|---|---|---|---|---|
| Runtime | YES | YES | YES | YES |
| Persistence | YES | YES | YES | YES |
| Localization | YES | YES | YES | YES |
| Structural projection | YES | YES | YES | YES |
| Phase 3 evidence builder | YES | YES | YES | **NO** |
| Phase 3 consumes Signature edges | N/A (classical global edges) | N/A | N/A | **NO** |
| Phase 4 history enricher | YES | YES | YES | **NO** |
| Live Narrative V2 | NO | NO | NO | NO |
| Live picker | YES | YES | YES | **NO** |

---

## Phase 6 seams

| ID | Seam | Classification | Notes |
|---|---|---|---|
| A | Generalized Narrative evidence input must resolve Signature spreads without pretending all spreads are Classical | **BLOCKER** before live Crossroads | Today `NarrativeEvidenceValidation.resolveSpread` → `ClassicalSpreadSemantics.byLegacyTypeName` only |
| B | Audited edge-provider seam for relationship scorer to consume Phase 5 edges without copying scorer / mutating global state / losing Classical parity | **BLOCKER** before live Crossroads | `kSignatureCrossroadsEdges` must remain Phase-5-owned until seam exists |
| C | Crossroads edge graph must produce real deterministic relationship evidence | **BLOCKER** before live Crossroads | Structural 4 edges / 7 relation rows exist in shadow; scoring does not |
| D | Signature history normalizer / source adapter for `signature.crossroads` | **BLOCKER** before live Crossroads | Frozen Phase 4 classicalFromSpread returns null today (intentional) |
| E | Recurrence: same-spread-alone must **not** authorize recurrence (`forbidSameSpreadAloneAuth=true`) | **BLOCKER** before live Crossroads | Preserve forever for launch catalog |
| F | H7 transitive physical identity remains intact | **MAJOR** before live V2 migration | Do not weaken Phase 4 identity firewalls |
| G | H19 deterministic ordering remains intact | **MAJOR** before live V2 migration | Exact-tie representative determinism |
| H | Privacy / owner / source-existence firewalls remain intact | **MAJOR** before live V2 migration | Including `privacyBlocked` short-circuit |
| I | Current 1/3/5 classical Narrative requests remain byte/semantic compatible | **BLOCKER** before live Crossroads | Classical shadow parity in 5E must not regress |
| J | Crossroads relationship `QuestionKind` remains unsupported | **BLOCKER** before live Crossroads | No silent remap to open/decision |
| K | Live picker remains disabled until Narrative V2 + result pipeline + visual gates are ready | **BLOCKER** before live Crossroads | `offeredInLivePicker=false` through 5F |
| L | No release-readiness claim solely from Phase 5 | **MAJOR** before live V2 migration | Phase 5 ≠ App Store ready for Crossroads Narrative |

### Counts

| Class | Count |
|---|---|
| **BLOCKER** before live Crossroads | **8** (A–E, I–K) |
| **MAJOR** before live V2 migration | **4** (F–H, L) |
| later / nonblocking | 0 recorded in this audit |

### Open Phase 5 blockers / majors

| Open Phase 5 BLOCKERS | **0** (5E shadow complete; Crossroads live deferred) |
| Open Phase 5 MAJORS | **0** |

---

## Explicit non-claims

- Phase 5E does **not** wire live Narrative V2.
- Phase 5E does **not** call `NarrativeEvidenceBuilder` for Crossroads.
- Phase 5E does **not** call `TarotNarrativeRequestEnricher` for Crossroads.
- Phase 5E does **not** insert Crossroads edges into `kAuthoritativePositionEdges`.
- Phase 5E does **not** claim scorer-output difference for Crossroads vs Deep Field.
- Phase 5E does **not** enable Crossroads in entry / ritual / table pickers.

---

## Next

**Phase 5F** — Independent final Signature Spreads audit (freeze candidate).  
Phase 6 implements the seams above under an explicit approved migration — not as a silent follow-on to 5E.
