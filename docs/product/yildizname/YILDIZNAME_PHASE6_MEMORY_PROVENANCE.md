# YILDIZNAME Phase 6 — Memory Provenance

**Status:** FROZEN  
**Engine:** `YildiznameArtifactMemoryEngine`  
**Merge:** `YildiznameThemeMerge` → Phase 5 `discoveryThemes` (max 3)

## Sources

Only Narrative V1 artifacts that:

- belong to current owner  
- pass integrity decode  
- still exist  

`legacyLocal` artefacts are **excluded** from Yıldızname-specific narrative memory.

## Recurrence rule

Theme is recurring only if:

1. Referenced by accepted result `themeRefs` (not merely available in request)  
2. Supported by **≥ 2** distinct prior artifacts  

Available-but-unused themes do not count.  
Current semantic operation is never prior evidence (no self-recursion).

## Provenance (local only)

label · supportCount · sourceArtifactIds · latestOccurredAt  

**sourceArtifactIds never go to the provider.**

## Delete / wipe

Deleted artifact drops support; below 2 → no longer recurring.  
A→B: zero theme / count leak.  
Account wipe clears artifact key.

## Merge with PersonalDiscovery

Prefer Yıldızname history themes; fill remaining slots from `observedRecurringLabels`; case-insensitive dedupe; max 3.  

Must **not** mutate NatalChartEvidence / facts-only fingerprint.

## Wording

No dated “your reading on March 4…” claims without an explicit future source contract.  
Allowed: reflective recurrence (“tekrar eden … teması”).
