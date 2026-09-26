# Yıldızname Phase 7G.1 — Historical Artifact State

**Status:** PASS  
**Base:** Phase 7G masters at `82b4ce43`  
**Closes:** Phase 7A forensic finding **B4** (product debt, not rewritten)

## Original B4

Phase 7A documented: *“No artifact ‘Kayıtlı yorum’ status chrome.”*

The Phase 7 visual contract required:

- LIVE = current/new reading  
- ARTIFACT = “Kayıtlı yorum” + original stored date  

`YildiznameResultPresentation.isHistoricalArtifact` existed, but
`StarMapResultBodyChildren` never consumed it. Live and artifact reopen could
therefore be byte-identical.

## Root cause

Presentation knew the source; the canonical body never rendered provenance.

## Source-based rule

| Source | Historical chrome |
|---|---|
| `legacyLive` | never |
| `narrativeLive` | never |
| `legacyArtifact` | yes, if `createdAtUtc` present |
| `narrativeArtifact` | yes, if `createdAtUtc` present |

Missing `createdAtUtc` on an artifact source ⇒ fail closed (no `DateTime.now()`).

Durable `artifactId` on a live source does **not** invent historical chrome.

## Localization

Chrome only (`star.result.historical.label`):

- TR: `Kayıtlı yorum`  
- EN: `Saved reading`  
- RU: `Сохранённое толкование`  

Date: `OraclyFormat.dateCompact(createdAtUtc)` — not relative day labels.

Line shape: `Kayıtlı yorum · 2 Tem 2026`

Stored narrative prose is never rewritten.

## UI

Widget: `StarMapHistoricalStatus`  
Order: app bar → **historical (artifact only)** → scope → facts → …

Quiet metadata. Not a banner, card, CTA, or badge.

## Action parity

Copy / share / favorite / continuation / OR payloads unchanged. Historical
chrome is not prepended to copy or share prose.

## Forensic hide (test-only)

`forensicHideHistoricalStatus` + `withForensicHideHistoricalStatus()` keep
frozen 7A–7F PNG inventories byte-stable. Phase 7G final masters never use it.
Production never sets the flag.

## Affected Phase 7G masters

Artifact / locale / responsive masters refrozen. Live masters A1/A2/B1/B2/E1
remained pixel-stable.

## Hash binding

`yildizname_phase7g_golden_hash_test.dart` now requires exact
`filename.png → sha256` row binding (not mere `contains(hash)`).
