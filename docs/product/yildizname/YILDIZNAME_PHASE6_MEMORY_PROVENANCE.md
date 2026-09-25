# YILDIZNAME Phase 6 — Memory Provenance

**Status:** FROZEN (Phase 6.1 theme identity hardened)  
**Engine:** `YildiznameArtifactMemory`  
**Identity:** `YildiznameThemeIdentity`  
**Merge:** `YildiznameThemeMerge` → Phase 5 `discoveryThemes` (max 3)

## Sources

Only Narrative V1 artifacts that:

- belong to current owner  
- pass integrity decode  
- still exist  

`legacyLocal` artefacts are **excluded** from Yıldızname-specific narrative memory.

## Provider themeRefs are request-local

Phase 5 assigns positional refs such as `theme.0`, `theme.1`, `theme.2` via
`YildiznameRequestExtras.themes(...)`.

Those refs mean: **reference to one request-local theme fact**.

They are **not** stable semantic identities across artifacts.

- Same `theme.0` in two requests may label different themes → must **not** recur.  
- Same label under `theme.0` and `theme.2` in different artifacts → **must** recur.

## Historical theme identity (Phase 6.1)

For **each artifact independently**:

1. Build `requestLocalThemeRef → label` from that artifact’s stored request `discoveryThemes`.  
2. Resolve accepted result `themeRefs` against **that same** map.  
3. Derive historical identity from the **resolved label**, never from the raw ref.

Canonical helper: `YildiznameThemeIdentity`

- Normalize: trim, collapse internal whitespace, Unicode `toLowerCase`  
- No ASCII transliteration, no fuzzy synonym merge, no cross-locale translation  
- Turkish `I`/`ı`/`İ` edge cases may yield false negatives under Unicode default
  casing — preferred over false positives / dangerous ASCII folding  
- Local key: `yth_` + first 16 hex of SHA-256(normalized label)  
- Key is **local history only** — never sent to the provider  
- Do **not** confuse with Phase 5 `themeRef`

Unknown accepted ref (not in that artifact’s request) → **fail closed**; no invented label; no memory evidence.

One artifact contributes **at most one** support per canonical key (duplicate / case-equivalent labels within one artifact do not inflate support).

## Recurrence rule

Theme is recurring only if:

1. Resolved from an accepted result `themeRef` that maps to a request label  
2. Supported by **≥ 2** distinct prior Narrative V1 artifacts  

Available-but-unused request themes do not count.  
Current semantic operation is never prior evidence (`excludeSemanticFingerprint`).

Ordering (deterministic):

`supportCount DESC` → `latestOccurredAt DESC` → `themeKey ASC`

## Provenance (local only)

`themeKey` · `label` · `supportCount` · `sourceArtifactIds` · `latestOccurredAt`

**sourceArtifactIds and themeKey never go to the provider.**

New provider requests may still assign fresh `theme.0`…`theme.2` for the **new** request only.

## Delete / wipe

Deleted artifact drops support; below 2 → no longer recurring.  
A→B: zero theme / count leak.  
Account wipe clears artifact key.

## Merge with PersonalDiscovery

Prefer Yıldızname history themes; fill remaining slots from `observedRecurringLabels`;
shared normalize via `YildiznameThemeIdentity`; max 3.

Must **not** mutate NatalChartEvidence / facts-only fingerprint.
Full semantic narrative fingerprint **may** change when merged history labels change.

## Immutability

Memory interpretation is **read-time only**. Never mutate stored artifact payload,
contentHash, semanticFingerprint, or result to repair identity.

## Future (non-blocking)

Cross-locale synonym taxonomy (e.g. Sabır ↔ Patience) is out of Phase 6.1 scope.
False negatives preferred over false positives. No AI translation.

## Wording

No dated “your reading on March 4…” claims without an explicit future source contract.  
Allowed: reflective recurrence (“tekrar eden … teması”).
