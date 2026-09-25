# TAROT Phase 7F — History / Reopen / Saved-Reading Fidelity

**Status:** implemented on `fix/final-product-remediation-20260922`  
**Depends on:** 7E Narrative result experience (FROZEN)

## Problem

Reopening a paid Tarot reading from History must show the **same** reading — not regenerate, reinterpret, or silently flip Narrative V2 ↔ legacy when remote flags change.

## Contract

1. **Persist presentation provenance** on `ReadingModel` (nullable strings):
   - `resultMode` — `narrativeV2` | `legacy`
   - `interpretationSource` — `ai` | `local` | `cache`
   - `deliveryKind` — `interpretation` | `recovery`
2. **Live save** (`ReadingScreen` → `saveFromSession`) writes the exact live mode/source/delivery.
3. **History reopen** uses `ReadingPremiumBody` with `modeOverride` from persisted mode (missing → conservative `legacy`). Never calls the live Narrative flag for persisted records.
4. **SavedReadingParser** never invents AI/local labels for old records (`sourceAttributionKnown`).
5. **Crossroads / seven** have honest history filters (not five / all).
6. **No provider / billing / InterpretationService** on History Detail.

## Out of scope

Phase 6 Narrative contract · backend · Evidence enrichment · public Crossroads picker
