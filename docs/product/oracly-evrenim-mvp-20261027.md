# ORACLY EVRENİM · MVP product + engineering contract

Issue: https://github.com/ftylmz32/oracly/issues/45
Created: 2026-10-27
Status: **Design/implementation contract, not a production-ready feature.**
Branch: `feat/oracly-evrenim-mvp-20261027`. Base: `fix/coffee-c21-private-meaning-handoff-20261006`.
Owner workflow: another branch handles payment/release fixes; no merge or deploy here.

## One-line proposition

"Falını sadece okuma. Deneyimlerini birbirine bağlayarak kendi evrenini oluştur."

This is an **interactive personal constellation editor** that uses only real stored experiences, not another AI-generated interpretation or merely an animated journal.

## User flow / screens

### 1. Journal > Evrenim (Map | List)
- Existing Journal remains functional. Prefer discoverable tab/toggle instead of a sixth bottom-nav tab.
- Empty state: dark sky, one empty central focus, `İlk keşfini başlat` routes to the actual supported initial free reading. No fake stars/readings, no mandatory signup/paywall.
- Populated map: each node is one reading from `discoveryJournalEntriesProvider` (kind + id + date + title), with deterministic position and kind-specific icon.
- Tap a star -> sheet: real title/date/kind/short **stored** preview; actions `Falımı aç` (reuse `DiscoveryJournalOpener`) and `Bir yıldızla bağla`.
- Select second star -> connection editor: explanation text (optional, max 280 characters) + Save. Visible connecting stroke appears between nodes.
- Tap existing edge -> edit/delete note; delete always reversible within UI state until persist confirmation.
- Map supports bounded pan/zoom; List remains fully operable for accessibility and large histories.

### 2. Story vignette (real data only)
1. User has a coffee reading from May and a tarot reading from June.
2. Two stars appear with real dates and titles.
3. User selects coffee star and tarot star, chooses `Bağlantı kur`, writes `İkisinde de yeni başlangıç hissi vardı.`
4. After reopening the app under the same account, the edge and note are there.
5. Tapping either endpoint opens **that user's actual original** reading. This is the differentiator.

## Data contract

Read-only reading source: `DiscoveryJournalEntry` objects from `discoveryJournalEntriesProvider`. Do **not** edit source records.

Avoid collisions by defining a `ReadingRef` as `(kind, id)`, never bare `id`. Unique node key: `kind:id`.

Proposed `EvrenConnection` fields:
- `id`: canonical, versioned stable key or UUID; user-specific
- `ownerUid`: mandatory (actual resolved owner, never anonymous unscoped data)
- `firstReadingKey`, `secondReadingKey`: canonical distinct endpoints
- `userNote`: trimmed <= 280 chars; untrusted input rendered as plain text
- `createdAt`, `updatedAt` timestamps, `schemaVersion:1`.

Connection creation must reject identical endpoints and duplicates (sorted canonical pair). On source-reading deletion, treat missing endpoints as invalid and clean/hide the orphaned connection without rehydrating the deleted content.

**Storage decision MUST be resolved with existing account owner and delete/auth architecture before implementation.** No global unscoped local preferences or cross-account cloud reads/writes. If reliable owner-scoped persistence cannot be established, keep the editor feature-flagged OFF rather than silently keeping insecure notes.

## Practical integration plan

Existing files verified on base branch:
- `lib/features/discovery_journal/providers/discovery_journal_providers.dart`
- `lib/features/discovery_journal/models/discovery_journal_entry.dart`
- `lib/features/discovery_journal/services/discovery_journal_opener.dart`
- `lib/features/discovery_journal/presentation/screens/discovery_journal_screen.dart`
- `lib/features/personal_discovery/models/cross_discovery_insight.dart`
- `lib/shared/navigation/oracly_navigation.dart`

New independent module suggested under `lib/features/evrenim/`:
- `models/` (`reading_ref.dart`, `evren_connection.dart`)
- `services/` (map layout, persist/reconcile, owner change handling)
- `providers/` (aggregated read-only nodes and owner-scoped saved links)
- `presentation/` (map/list shell, accessible node details, connection editor)

Start with **read-only map** and original-reading navigation. Only then add persisted user-created edges; do not bundle a new data store and visual screen in a single untested change.

## UI specifics / quality

- Deep navy-black `#02030A`, muted violet `#5A3FD6`, warm gold `#E8C872`, ivory `#F3EADF` aligned with existing ORACLY visual identity.
- Focus a handful of nearby stars at launch. Pan and pinch zoom; map orientation should be deterministic (never reshuffle just because rebuilt).
- Performance: clamp visible node count per viewport, use simple vector strokes rather than heavyweight particle simulations, and honor reduced-motion preferences.
- Accessibility: keyboard/screen reader labels including date/type/title; full list equivalent; touch targets >= 44 logical pixels where practical; small-phone text-scale QA.
- All "cross-reading themes" if ever shown must be grounded in existing saved data; *never* output AI-fabricated connections.

## Must-pass tests

1. 0 / 1 / 2 / 30 / 100+ real journal records.
2. Duplicate record ids across distinct kinds still form distinct stars.
3. Tap star -> open correct exact original, including missing/deleted source failures.
4. Connection CRUD, note limit, zero-length note, duplicate pair and same-node rejection.
5. Persist across app restarts and reconnect; owner isolation A->logout->B->A; late provider response never leaks owner A to B.
6. Anonymous linking, account deletion, revoked access, malformed old JSON, failed storage write, offline restart.
7. Zoom/pan, reduced motion, large text, screen-reader/list parity, performance on budget Android/iOS.
8. Critical existing payment, gem, coffee reading, reading history and deletion regressions remain green.

## Release & App Store truth

- Feature behind a flag until integration/unit/widget tests + on-device E2E pass; do **not** claim PASS based on source review.
- No modification to interpretation prompts/motors, frozen coffee V3, IAP/refund, existing billing, deploy or Apple submission as part of this feature branch.
- Apple guideline 4.3(b) has an elevated bar for fortune-telling apps. Proof should be true screenshots/videos of **working** user-directed constellation linking, not a cinematic poster. Approval not guaranteed.
- No new premium requirement, AI call or gem charge for initial Evrenim use.

## Explicit non-goals

A game, streak mechanic, yet another fortune category, AI mental health insights, synthetic emotional claims, fake coffee image annotations, third-party sharing, social feeds and a new store SKU.
