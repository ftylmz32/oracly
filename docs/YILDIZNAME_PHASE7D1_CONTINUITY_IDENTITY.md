# Yıldızname Phase 7D.1 — Continuity Identity & Owner Firewall

**Status:** remediation  
**Parent:** Phase 7D

## Defects closed

1. **Current self-count** — history that included the current artifact with a
   null/blank `semanticFingerprint` could inflate support ≥ 2. The projector now
   always strips `current.id` and **fail-closes** when the current semantic
   fingerprint is null/blank (cannot prove another ID is not the same operation).

2. **Owner firewall** — projector filters history to
   `artifact.ownerId.trim() == current.ownerId.trim()` and rejects blank owners.
   Provider isolation remains; this is defense in depth.

## Phase 6

Unchanged. Prefilter lives only in `YildiznameContinuityProjector`.
