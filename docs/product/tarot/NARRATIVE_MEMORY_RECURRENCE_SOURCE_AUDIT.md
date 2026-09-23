# Narrative Memory + Historical Recurrence — Source Audit (Phase 4.0)

**Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Start HEAD:** `bfa64996d4934c0fe28c709376280a320fd570e1`  
**Phase 3 baseline:** FROZEN (`8434b26e` audit · READY TO FREEZE = YES)  
**Kind:** Forensic / design only — **no production changes**

---

## Executive summary

Tarot currently persists through **two independent stores**. Connected memory uses a **third** store (`OraclyMemoryStore`). Journey / PersonalMemory layers are **not** recurrence authorities.

| Authority candidate | Verdict for Phase 4 |
|---|---|
| `ReadingSession` | **Canonical FACT source** for Tarot card/position/orientation recurrence |
| `ReadingModel` | Journal / UI / interpretation companion; enriches intention/aiSummary; **not** positionKey authority |
| `OraclyMemory` | **Canonical** cross-feature theme + memory-evidence authority |
| `JourneyPersonalizationHints` | Migration / presentation only — **never** authorizes recurrence counts |
| `PersonalMemorySummary` | OR/discovery compact — **not** Tarot V2 evidence authority |

**Phase 3 debt carried (do not fix in 4.0):** MINOR-01 `themeOverlapMin` unused literal in scorer.

---

## 1 — History source inventory

### 1.1 ReadingModel (`or_reading_history`)

| Aspect | Fact |
|---|---|
| Storage | `MockHistoryRepository` SharedPreferences key `or_reading_history` (RemoteHistoryRepository **unused** by providers) |
| Write owner | `ReadingService.saveFromSession` ← `ReadingScreen._persistToJournalBody` (after interpretation) |
| Delete owner | `HistoryService.remove` / `clear`; PrivacyDiscoveryClear |
| Completed filter | **None** — every saved row is a journal entry |
| Ids | `id`, optional `sessionId` (happy path: both = `session.id`) |
| Owner | `userId` optional |
| Timestamp | `createdAt` = wall clock at journal save (**not** session `startedAt`) |
| Spread | Localized `spreadType` **label string** |
| Cards | `ReadingCardSnapshot`: ritual `cardId` int, `positionIndex`, `positionLabel`, `isReversed` — **no `positionKey`**, **no canonical string id** |
| Question | Clipped `intention` via `TarotHistoryPrivacy` |
| Interpretation | `aiSummary` |
| Journal | User note / tags / favorites |
| Epistemic | Cards/orientation: FACT (when written); aiSummary: INTERPRETATION; journal: USER-PROVIDED; intention: USER-PROVIDED (clipped) |

### 1.2 ReadingSession (`or_tarot_reading_sessions`)

| Aspect | Fact |
|---|---|
| Storage | `TarotLocalDataSource` keys `or_tarot_reading_sessions`, `or_tarot_active_session` |
| Write owner | `TarotReadingController._persist` throughout; `completeSession()` on journal path |
| Delete owner | `deleteSession` exists — **no production UI caller**; PrivacyDiscoveryClear wipes sessions |
| Completed filter | `status == ReadingSessionStatus.completed` (`fetchCompleted`) |
| Ids | `id`, optional `userId` |
| Timestamps | `startedAt`, `completedAt?`, `durationMs?` |
| Spread | `TarotSpreadType` enum name in JSON |
| Cards | Full `TarotCard` (ritual int `id`) + `positionIndex`, `positionLabel?`, **`positionKey?`**, `isReversed` |
| Question | Full `intention` + `intentionTopic` |
| Interpretation | `interpretation?` string |
| Epistemic | Ritual/orientation/positionKey: FACT; interpretation: INTERPRETATION |

### 1.3 OraclyMemory (`oracly_connected_memory_v2`)

| Aspect | Fact |
|---|---|
| Cap | `maxItems = 160` |
| Write | Feature stores / factories on save |
| Delete | `removeBySource(sourceId)` on source delete (see §5) |
| Attribution | `source.id`, `source.type` (`OraclyReadingType`), `occurredAt` |
| Themes | Deterministic TR keyword map (max 8) |
| Epistemic | Summary: INTERPRETATION; themes: DERIVED; source ids/dates: FACT |

### 1.4 PersonalMemorySummary (`or_personal_memory_v1`)

OR companion / discovery compact. Themes from discovery cross-insights. **Not** Phase 4 recurrence authority.

### 1.5 JourneyPersonalizationHints

Derived from prior `ReadingModel`s + discovery extras. `recentCardNames` / `recurringThemeLabels` are **migration hints only** (Phase 3 contract).

---

## 2 — Duplicate Tarot history analysis

| Question | Answer |
|---|---|
| Every completed session → ReadingModel? | **No** (saveFromSession can fail after completeSession) |
| Every ReadingModel → session? | **No** (`sessionId` optional; legacy ids) |
| Canonical card string persisted? | **Neither** store — ritual int only; map via `OraclyTarotBridge.byRitualId` |
| `positionKey` preserved? | **Session only** |
| Orientation | Both on happy path; missing defaults `false` |
| Authoritative user delete | HistoryService.remove (**ReadingModel only**) — session **orphans** |
| Dual representation | Same physical reading may exist in both stores |
| Dedupe key | `session.id` ↔ `reading.sessionId ?? reading.id` |

### Canonical strategy (LOCKED)

**A — ReadingSession is canonical for Tarot historical FACTS.**  
ReadingModel is **legacy/journal enrichment** for clipped intention / aiSummary / journal when session exists; journal-only rows may contribute **memory INTERPRETATION** when linked, but **card recurrence requires session (or reconstructable) FACTS**.

Phase 4C **must** couple `HistoryService.remove(id)` → `deleteSession(id)` (when present) so journal delete removes future recurrence influence.

---

## 3 — Connected memory write/delete truth table

| Source | Upsert on save | `removeBySource` on delete | Discovery clear | Notes |
|---|---|---|---|---|
| Tarot | Yes (`Factory.tarot`) | Yes | Yes (via history clear) | Source id = reading id |
| Coffee | Yes | Yes | Yes | No image bytes |
| Palm | Yes | Yes | Yes | No image path in memory |
| Dream | Yes | Yes | Yes | Analysis summary; tags+keywords |
| SoulMate | Only if authoritative interpretation | Yes on `clear()` | **No** (intentionally kept) | No portrait inference |
| Birth chart | Journey-ready only | Yes | Yes | No daily catalogue / raw placements |
| Daily astrology catalogue | **No writer** | — | — | Must remain excluded |
| Companion OR fact | Manual stableFact | Not discovery-coupled | Account wipe only | Out of Phase 4 Tarot scope unless approved |

**R1 privacy:** Source deletion removes connected-memory influence for Tarot/Coffee/Palm/Dream/BirthChart. SoulMate survives Discovery clear by design.

---

## 4 — Findings (Phase 4.0 — do not repair here)

| ID | Severity | Area | Why it matters |
|---|---|---|---|
| F-H01 | **MAJOR** | Tarot delete | Journal delete does not delete ReadingSession → orphan sessions would feed recurrence if session-primary |
| F-H02 | **MAJOR** | Dual store | Incomplete dual-write / dual-delete desync |
| F-H03 | **MINOR** | ReadingModel | Drops `positionKey` at `saveFromSession` |
| F-H04 | **MINOR** | ReadingModel time | `createdAt` ≠ ritual `startedAt`/`completedAt` |
| F-H05 | **INFO** | RemoteHistoryRepository | Unused by providers |
| F-H06 | **INFO** | SoulMate discovery clear | Connected memory retained by design |
| F-P01 | **INFO** | Phase 3 | MINOR-01 `themeOverlapMin` literal drift — carried, not fixed |

**BLOCKER count:** 0 (design can close F-H01/F-H02 in 4C)  
**MAJOR count:** 2  
**MINOR count:** 2 (+ Phase 3 MINOR-01 carried)  
**INFO count:** 3

---

## 5 — Implications for Phase 4 spec

1. Pure Phase 3 builder stays sync/storage-free.  
2. Session-primary adapter + optional ReadingModel enrichment.  
3. OraclyMemory = theme/memory authority.  
4. JourneyHints / PersonalMemorySummary = non-authoritative.  
5. Delete coupling is a **4C hard gate**.  
6. Legacy rows without reconstructable FACTS are **omitted**, never invented.

See companion: `NARRATIVE_MEMORY_RECURRENCE_SPEC.md`.
