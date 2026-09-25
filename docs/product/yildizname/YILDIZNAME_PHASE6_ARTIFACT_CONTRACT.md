# YILDIZNAME Phase 6 — Artifact Contract

**Status:** IMPLEMENTED / FROZEN  
**Storage key:** `yildizname_artifacts_v1`  
**Schema:** `artifactSchemaVersion = 1`

## Sources

| Source | Meaning |
|--------|---------|
| `legacyLocal` | Exact snapshot of symbolic StarMap leaf (skyMessage / innerArchive / planetCatalogue) |
| `narrativeV1` | Accepted Phase 5 structured request + result |

Never blur sources.

## Identity

- Opaque id: `yid_<32 hex>` via `Random.secure()`
- Not derived from Object.hash, title, locale, day, or prose alone
- Favorite id: `starMap:<artifactId>` · sourceRef = artifactId

## Required fields

id · ownerId · createdAtUtc · source · resultLocale · scope/fidelity (as applicable) · versions · evidence/semantic fingerprints (when narrative) · contentHash · payload

## Forbidden in artifact

birthDate · birthTime · birthPlace · latitude · longitude · timezoneId · UTC birth instant

## Integrity

SHA-256 `contentHash` over canonical payload+metadata (excluding contentHash).  
Mismatch → fail closed. Never regenerate.

## Immutability

No in-place update. New reading → new artifact.  
`saveNew` rejects same id with different content; identical save returns existing.

## Owner

Canonical `UserLocalDataIsolation.ownerKey`.  
Owner unavailable → typed failure; no wipe; no cross-owner access.

## Wipe

`UserLocalDataWipe` clears `yildizname_artifacts_v1`.
