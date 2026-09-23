# Narrative Memory + Historical Recurrence — Implementation Spec (Phase 4.0)

**Status:** DESIGN LOCKED — ChatGPT hardening applied · Phase 4A implemented (card recurrence pure)
**Date:** 2026-09-23
**Companion forensic:** `NARRATIVE_MEMORY_RECURRENCE_SOURCE_AUDIT.md`
**Phase 3:** FROZEN — do not modify scorer / selector / builder / profiles

**OPEN PHASE 4 IMPLEMENTATION DECISIONS: 0**

### ChatGPT review hardening (locked overrides)

| ID | Lock |
|---|---|
| H1 | `RecurringOccurrence.orientationKnown` (default `true`); unknown → `orientationKnown=false`, `isReversed=false` sentinel |
| H2 | `TarotHistoricalReadingRecord.topicId` is an explicit structured field (never recovered from AI prose) |
| H3 | Future rows ineligible: require `occurredAt <= now` **and** age `<= Duration(days: 90)` (no `abs`) |
| H4 | `occurrenceCount` = distinct eligible **prior readings** containing the card; per-reading duplicate card occurrences deduped |
| H5 | `MemoryEvidenceEntry` additive metadata amendment **deferred to Phase 4B** (not 4A) |
| H6 | Generic/sentinel topics never authorize `topic_match` (`isMeaningfulTopic`) |
| H7 | Eligible history **dedupes physical reading identity** before scan bound |
| H8 | Short alias `aşk` → `ilişki` supported; ASCII `ask` **excluded** (EN verb ambiguity) |
| H9 | `included=true` → `omitReason='included'`; false → `no_history`/`empty`/`irrelevant`/`privacy`(4C only) |
| H10 | Theme `supportingReadingIds` use typed refs `<sourceType>:<sourceId>` |
| H11 | Support refs capped by `maxRecurringOccurrencesListed` (default 5) |
| H12 | Free-text memory relevance requires ≥2 shared meaningful tokens |
| H13 | Connected-memory dedupe by `(sourceType, sourceId)` before scoring |
| H14 | Owner-safe Tarot live source ids come **only** from accepted TarotHistorySourceAdapter rows (never raw HistoryService/session rescan) |
| H15 | Connected-memory deletion is typed by `(sourceType, sourceId)` via `removeBySourceAndType` |
| H16 | Historical `questionKind` / `intentionSummary` / `topicId` share the same effective session→ReadingModel fallback source |
| H17 | Accepted session-backed Tarot live-source aliases are **only** `session.id` + linked `ReadingModel.id`. `linked.sessionId` never independently authorizes source existence |
| H18 | Enrichment receives `currentOwnerId` and `privacyBlocked` **explicitly** — neither may be inferred from history; `privacyBlocked` has **no default**; `privacyBlocked=true` short-circuits all historical engines and yields `omitReason=privacy` |

---

## 0 — Non-negotiables

1. `NarrativeEvidenceBuilder.build` remains **pure, sync, storage-free**.  
2. Phase 4 adds a **separate enrichment boundary**.  
3. No invented memory / fake recurrence / same-reading theme echo as history.  
4. No deleted-source ghost influence.  
5. No cross-owner leakage.  
6. No AI calls in Phase 4 engines.  
7. RequestBounds stay **20 / 5 / 12 / 800 / 4**. Lookback **90 days** is provider policy only.  
8. Live Tarot user path remains unwired (shadow) until later approval.  
9. Phase 3 MINOR-01 (`themeOverlapMin`) is **carried**, not fixed.

---

## 1 — Architecture (LOCKED)

```
Storage / repositories
        ↓
TarotHistorySourceAdapter + ConnectedMemorySourceAdapter
        ↓
TarotHistoricalSnapshot  (normalized, owner-filtered, clock-aware)
        ↓
PURE engines:
  • TarotCardRecurrenceEngine
  • TarotThemeRecurrenceEngine
  • TarotMemoryEvidenceEngine
        ↓
TarotNarrativeRequestEnricher.enrich(
  base: TarotNarrativeRequest,   // Phase 3 closed universe
  history: TarotHistoricalSnapshot,
  currentOwnerId: String?,       // explicit — never inferred (H18)
  privacyBlocked: bool,          // required — no default (H18)
  now: DateTime,                 // injected clock
) → TarotNarrativeRequest        // NEW closed request
```

`privacyBlocked=true` short-circuits card/theme/memory engines and returns empty Phase 4 fields with `omitReason=privacy`. Owner id is never written onto the request.

### Enrichment mutates ONLY

- `memory`
- `recurringCards`
- `recurringThemes`

### Must remain byte/functionally identical from Phase 3 base

`narrativeTarotVersion`, `languageCode`, `sessionId`, `readingId`, `question`, `spread`, `cards`, `relationships`, `bounds`

No rescoring of current-spread relationships after history injection.

---

## 2 — Canonical Tarot history strategy (LOCKED)

**Strategy A — ReadingSession is canonical for FACTS.**

| Fact | Source |
|---|---|
| readingId / sessionId | `ReadingSession.id` |
| occurredAt | `completedAt ?? startedAt` (UTC instant) |
| spreadId | normalize `TarotSpreadType.name` → classical `spreadId` |
| cards / ritual id | `TarotDrawnCard.card.id` → `OraclyTarotBridge.byRitualId` → canonical |
| orientation | `isReversed` |
| positionKey / index | session fields |
| intention summary | prefer session intention (sanitized); else ReadingModel clipped intention |
| aiSummary | ReadingModel / session interpretation = **INTERPRETATION only** |

**Dedupe key:** `session.id` ↔ `ReadingModel.sessionId ?? ReadingModel.id`

**Union role:** adapter may discover journal-only or session-only rows for upgrades, but:

- **Card recurrence samples require reconstructable FACTS** (canonical id + occurredAt + readingId).  
- Missing `positionKey`: see §14.  
- Missing orientation confidence: see §15.

---

## 3 — Normalized models (conceptual)

```
TarotHistoricalReadingRecord
  readingId: String
  sessionId: String?
  ownerId: String?
  occurredAt: DateTime          // UTC instant
  spreadId: String              // classical machine id
  questionKind: QuestionKind?   // recoverable via ReadingAsk when text exists
  topicId: String?              // structured machine topic (H2) — never from AI prose
  intentionSummary: String?     // sanitized, bounded
  cards: List<TarotHistoricalCardOccurrence>
  interpretationSummary: String?  // INTERPRETATION, optional

TarotHistoricalCardOccurrence
  canonicalCardId: String
  isReversed: bool              // factual iff orientationKnown; else inert sentinel
  orientationKnown: bool        // H1 — default true on known rows
  positionKey: String?          // null if unrecovered
  positionIndex: int?
```

Epistemic tags: FACT / USER-PROVIDED / INTERPRETATION / DERIVED — never collapse INTERPRETATION into FACT.

---

## 4 — Owner isolation (LOCKED)

| Current request `ownerId` | Include historical rows |
|---|---|
| Non-null | Only rows with **same** `ownerId` |
| Null (local anonymous) | Only rows with **null** `ownerId` from the **same device local store** |

**Ownerless legacy rows are excluded** when current request is owner-bound.  
Never include another owner’s rows. Never log raw owner ids.

---

## 5 — Current reading exclusion (LOCKED)

Exclude historical row if:

```
historical.readingId == current.readingId
OR (both sessionIds non-null AND historical.sessionId == current.sessionId)
```

No self-recurrence.

---

## 6 — Completed-only (LOCKED)

| Representation | Eligible iff |
|---|---|
| ReadingSession | `status == completed` AND (`completedAt != null` OR drawn cards non-empty with completed flag) |
| ReadingModel (enrichment only) | Present as saved journal row linked by dedupe key; never alone for positionKey FACT |
| OraclyMemory | Existing store entry (already written only on completed/authoritative saves) |

Exclude: in-progress, abandoned, active-session-only, failed, quality_unavailable / non-authoritative SoulMate, non-journey Birth Chart.

---

## 7 — Lookback / scan bounds (LOCKED)

1. Filter owner + completed + exclude current.
2. UTC instants: require `occurredAt <= now` **and** `now.difference(occurredAt) <= Duration(days: 90)` (**inclusive exact 90 days**). **Future rows excluded** (H3 — no `abs`).
3. Sort **newest first** by `occurredAt`, then `readingId` ascending.
4. **Dedupe physical reading identity** (H7) — keep first (newest) row per identity; no field merge.
5. Take at most **`RequestBounds.maxPriorReadingsScanned = 20`** distinct Tarot FACT records.

**Physical identity (H7)** — duplicate if any of:

- same non-empty `readingId`, OR
- both non-empty `sessionId` equal, OR
- one row’s `readingId` equals the other’s non-empty `sessionId`, OR
- one row’s non-empty `sessionId` equals the other’s `readingId`

(Reflects Phase 4.0 seam: `session.id ↔ reading.sessionId ?? reading.id`.)

Timestamps treated as **UTC instants**. No calendar-local day boundaries. Pure engines receive injected `now` — **no `DateTime.now()` inside pure logic**.

---

## 8 — Historical card recurrence (LOCKED)

Authority: `TarotRecurringCardEvidence` only.

- Candidates = **current draw** canonical ids only.
- Recurring iff same `canonicalCardId` appears in ≥1 eligible **PRIOR** Tarot FACT reading.
- `occurrenceCount` = number of **distinct eligible prior reading records** containing the card (H4; **current not included**).
- Within one historical reading, duplicate same-card occurrences are **deduped** (lowest `positionIndex`, then `positionKey`, then `orientationKnown=true`, then `isReversed=false` tie-break).
- `occurrences` = prior samples only, newest first, max **`maxRecurringOccurrencesListed = 5`**.
- Sample fields: `readingId`, `at`, `spreadId`, `positionKey` (required in sample — skip sample if positionKey unknown), `isReversed` + `orientationKnown` (H1), `intentionSummary?`.

### Ranking (multi-card)

1. `occurrenceCount` DESC  
2. most recent prior `at` DESC  
3. current `positionIndex` ASC  
4. `canonicalCardId` ASC  

### Evidence ids

After ranking: `rec_card_01` … opaque, request-scoped. No encoded user/card/source text.

### `contextsOverlap` (LOCKED)

`true` iff **any** of:

1. Exact normalized **meaningful** topic id match (H6) between current intention topic and historical `topicId` — both non-null, non-empty, and **not** in the generic sentinel set (`general`, `genel`, `guidance`, `general guidance`, `genel rehberlik`, `open`, `other`, `общий`, `общее`, `общая опора`), OR  
2. Same recoverable `QuestionKind` ∈ {relationship, decision} **and** ≥1 shared sanitized token (length ≥4) between current `question.rawText` and historical intentionSummary after TR/EN/RU stopword strip, OR  
3. Shared `NarrativeKeywordIds` intersection size ≥1 between current profile-slice keywords (any current card) and historical intention/topic tokens mapped via the frozen theme→keyword map (§12). Short theme alias **`aşk` → `ilişki`** is explicitly supported (H8); ASCII **`ask` is not** a relationship alias.

**False** if insufficient reliable context (safer).  
Sole same-card / same-spread / generic tokens (`the`, `and`, `bir`, `ve`, …) → **false**.  
Generic topic sentinels alone → **false** (no fall-through to keyword_map unless another independent theme alias exists in intention text).

`overlapSummaryKey`: machine key only, e.g. `topic_match` | `kind_token` | `keyword_map` | null.

---

## 9 — Historical theme recurrence (LOCKED)

Authority: `TarotRecurringThemeEvidence`  
**Distinct from** `RelationshipKind.themeRepetition` (current-spread only). Never convert either way.

### Connected memory authority

**`OraclyMemoryStore` / `OraclyMemory` only.**

Not authoritative:

- `JourneyPersonalizationHints.recurringThemeLabels`
- `PersonalMemorySummary.themes`
- `recentCardNames` / `recurringThemeLabels` on request (remain **EMPTY**)

### Cross-feature rule

Theme qualifies only if same normalized `themeId` is supported by **≥2 distinct `OraclyReadingType`** values among eligible memory sources within lookback (adapter may use memory `occurredAt` and source filters).

Two Tarot-only memories → **do not** qualify as historical theme evidence (card recurrence covers Tarot-only).

### Allowed source types

`tarot`, `coffee`, `palm`, `dream`, `soulmate`, `birthChart`  

Excluded: daily catalogue astrology, raw placements, OR chat transcripts (unless separately approved stableFact contract — **out of Phase 4 Tarot scope**).

### Firewalls

| Feature | Include iff |
|---|---|
| SoulMate | Authoritative text interpretation only — never portrait/image |
| Coffee / Palm | Completed authoritative result — not capture-only / quality_unavailable |
| Birth chart | Journey-ready interpreted result only |
| Dream | Completed analysis memory; for future Dream feature: no self-echo merely because prior Dream exists |

### Theme fields

- `themeIdOrLabel`: normalized theme id (`karar`, `ilişki`, …)  
- `supportCount`: distinct eligible **source records**  
- `supportingReadingIds`: unique source ids, newest-first, bounded  
- `relatedCardIds`: ⊂ **current** request cards with map hit (§12)  
- `relevanceToCurrentAsk`: [0,1] deterministic (§13)  

Max themes in request: **`maxThemeLabels = 4`**.

### Theme evidence ids

`rec_theme_01` …

---

## 10 — Theme normalization map (LOCKED)

Maps OraclyMemoryFactory theme ids → `NarrativeKeywordIds` subsets (review-locked for v1):

| themeId | NarrativeKeywordIds |
|---|---|
| `karar` | choice, direction, indecision, pause |
| `ilişki` | intimacy, union, reciprocity, attachment, belonging |
| `değişim` | change, renewal, ending, opening |
| `sınır` | boundary, closing, resistance |
| `kariyer` | craft, discipline, direction, externalDemand |
| `iletişim` | communication, harshSpeech, truth |
| `belirsizlik` | confusion, doubt, indecision |
| `özgüven` | courage, agency, boast |

Unknown theme → no card relation. No fuzzy expansion.

---

## 11 — Theme ↔ current ask relevance (LOCKED)

Score in [0,1], max of applicable:

| Condition | Score |
|---|---|
| Current QuestionKind = guidance/open and no topic and no map overlap | 0.0 (exclude unless score≥0.35 from other rows) |
| Theme keywords ∩ current card keywordIds non-empty | 0.55 |
| Theme id matches normalized current topic tokens | 0.70 |
| QuestionKind = relationship and theme = `ilişki` | 0.80 |
| QuestionKind = decision and theme = `karar` | 0.80 |
| Explicit recall active (§17) and theme present | max(score, 0.50) |

Include theme iff score ≥ **0.35** AND cross-feature rule holds.  
TR/EN/RU: topic/kind signals preferred over language-specific tokens; keyword map is language-agnostic ids.

---

## 12 — Memory evidence (LOCKED)

Field: `TarotNarrativeMemoryEvidence`

| Field | Behavior |
|---|---|
| `entries` | Up to **4** `MemoryEvidenceEntry` from OraclyMemory |
| `priorReadingCount` | Eligible prior **Tarot FACT** readings after owner/current/90d filters, **capped at 20** (scanned count — not lifetime) |
| `included` | true iff ≥1 entry after relevance |
| `omitReason` | `empty` \| `irrelevant` \| `no_history` \| `privacy` |
| `recentCardNames` | **always []** |
| `recurringThemeLabels` | **always []** |

### Memory model amendment (LOCKED — YES · **Phase 4B IMPLEMENTED**)

Phase **4B** extends `MemoryEvidenceEntry` (additive, backward-compatible constructors) with:

- `sourceType` (`TarotConnectedMemorySourceType` name string)  
- `sourceId`  
- `occurredAt`  
- `confidence`  
- `epistemic` (`MemoryEvidenceEpistemic`)  

`omitReason` when included: **`included`** (H9). Pure 4B never emits `privacy`.

Existing fields remain. Phase 3 empty shell unchanged until enrichment.

### Entry bounds

- Max entries: **4**  
- Each `contentForModel` ≤ **220** chars  
- Combined content chars ≤ **`maxMemoryChars = 800`**  
- Prefixed epistemic framing required in content, e.g. `[INTERPRETATION][tarot]` — never imply life-fact certainty from prior symbolic readings.

### Memory refs

After ranking: `mem_01` … `mem_04`.

### Memory ranking

Score = `relevance*0.50 + recency*0.30 + confidence*0.20`  
`recency = 1/(1+ageDays/30)` using injected `now`.  
Tie-break: `occurredAt` DESC, `sourceType` ASC, `sourceId` ASC.

### Memory relevance (LOCKED)

Include only if:

- token/theme overlap with current real question/topic, OR  
- theme map hits current card keywords, OR  
- explicit recall (§17)  

If no real question **and** no keyword/theme match → `included=false`, `omitReason=irrelevant`.

---

## 13 — Explicit recall (LOCKED)

Reuse/adapt `OraclyMemoryRetriever` recall lexicon (`hatırla`, `önce`, `geçen`, `remember`, `before`, `previous`, `similar`, …).

Effects:

- May relax recency weight / allow older-within-90d rows that barely miss relevance  
- **Never** bypass deleted sources, owner isolation, or fabricate entries  

---

## 14 — Legacy position policy (LOCKED)

If `positionIndex` known and spread unambiguously maps to classical catalog and index ∈ positions → reconstruct `positionKey`.  
Otherwise: **omit that occurrence sample** (do not invent). Card may still count toward `occurrenceCount` if canonical id + date known; samples listed only with valid `positionKey`.

---

## 15 — Legacy orientation policy (LOCKED)

If orientation missing/untrusted: set `orientationKnown=false`.  
Card recurrence identity still allowed.  
Do **not** default to upright for listed samples; omit `isReversed` claims in samples when unknown (store `false` only when known upright — prefer skipping sample orientation field via `orientationKnown` gate in engine).

ReadingModel’s historical default `false` is **not** trusted as known upright for upgraded ambiguous rows; session `isReversed` is trusted when present.

---

## 16 — Legacy card id policy (LOCKED)

Map ritual ints **only** via `OraclyTarotBridge.byRitualId`.  
Never match by localized name / image path / substring.  
Unmappable → omit occurrence.

---

## 17 — Malformed history policy (LOCKED)

| Case | Behavior |
|---|---|
| Current Phase 3 input invalid | **Hard fail** (existing typed errors) |
| One historical row malformed | **Skip row**; continue enrichment |
| Owner mismatch | **Never include** |
| Diagnostics | Test-only counters; no private question/owner in logs |

---

## 18 — Deletion / clear / restart (LOCKED)

| Action | Required Phase 4C behavior |
|---|---|
| Delete one Tarot journal reading | Remove ReadingModel **and** matching ReadingSession **and** `OraclyMemory.removeBySource` |
| Clear Tarot / Discovery history | Existing PrivacyDiscoveryClear + session wipe; verify no ghost recurrence |
| Clear one category | Other features’ memory remains |
| Account wipe / logout switch | Full connected memory key wipe; no cross-account residue |
| Restart after delete | Derived recurrence rebuilt from live stores — **no denormalized recurrence cache** |

**Tarot delete → card recurrence delete:** design **PASS** iff 4C delete coupling lands.

---

## 19 — Storage bounds (LOCKED)

- OraclyMemoryStore.maxItems = **160** (reuse)  
- No second Phase 4 history database  
- Prefer read adapters over duplication  

---

## 20 — Referential integrity (enrichment exit)

- `mem_*`, `rec_card_*`, `rec_theme_*`, `rel_*` namespaces non-colliding  
- All ids unique within request  
- Recurring card canonical ids ⊆ current cards  
- Theme `relatedCardIds` ⊆ current cards  
- Supporting ids correspond to snapshot sources  
- Collections defensively immutable  

---

## 21 — Failure / privacy table (summary)

| Field | Epistemic | → AI? | Max | Deletion |
|---|---|---|---|---|
| canonicalCardId | FACT | yes (structured) | id | with source |
| orientation | FACT | yes if known | bool | with source |
| positionKey | FACT | yes if known | key | with source |
| occurredAt | FACT | yes (date) | instant | with source |
| intentionSummary | USER | bounded yes | clipped | with source |
| aiSummary / memory content | INTERPRETATION | bounded yes | 220/entry | with source |
| journal note | USER | **no** by default | — | with source |
| ownerId | FACT | **never** | — | n/a |
| themeId | DERIVED | yes | id | with sources |

Analytics/share: no private question dumps; no owner ids.

---

## 22 — Phase 4 subphases (LOCKED)

### 4A — Normalized models + Tarot card recurrence pure engine

- Production: `lib/features/tarot/narrative/history/*` + `RecurringOccurrence.orientationKnown`
- Depends: Phase 3 freeze
- Tests: `test/features/tarot/narrative_history/`
- Stop: card recurrence pure unit PASS · **IMPLEMENTED**

### 4B — Theme recurrence + memory relevance pure engines

- Production: connected-memory models/eligibility · theme engine · memory engine · recall · `MemoryEvidenceEntry` additive metadata  
- Theme: ≥2 distinct source types · themeIds authority · `rec_theme_##` · typed support refs  
- Memory: relevance/ranking/chars · `mem_##` · omitReason H9 · hints always []  
- Stop: pure engines PASS · **IMPLEMENTED**

### 4C — Adapters + owner isolation + delete integrity · **IMPLEMENTED / PASS**

Production:

- `TarotHistorySourceAdapter` — ReadingSession FACT-primary · ReadingModel enrichment/legacy
- `TarotConnectedMemorySourceAdapter` — OraclyMemory reading kinds · themes pass-through
- `TarotHistoricalSnapshotLoader` — owner boundary · live-source existence firewall
- `TarotHistoryDeletionService` — journal ↔ session ↔ memory coupling
- `OraclyMemoryStore.removeByType` · Discovery clear orphan type purge (not soulmate)

Owner boundary:

- `currentOwnerId` must equal `UserLocalDataIsolation.ownerKey` local owner (both null allowed)
- mismatch → `privacyBlocked=true` · empty snapshot (no partial memory)

Row policy: owner-bound excludes ownerless legacy; other owners excluded; linked owner conflict drops physical reading.

Source-existence firewall (read-side):

- tarot / coffee / palm / dream / soulmate (authoritative only) / birthChart (journey-ready)
- stale OraclyMemory without live source → DROP

Delete coordinator: all user-facing single Tarot deletes route through `TarotHistoryDeletionService` (ReadingHistoryDetailScreen).

Request enricher: **IMPLEMENTED** (4D · shadow). Live Narrative V2: **UNCHANGED**.

Stop: privacy red-team PASS · **IMPLEMENTED**

### 4D — Request enricher + frozen historical corpus · **IMPLEMENTED / PASS**

- `TarotNarrativeRequestEnricher.enrich(...)` — pure sync · card → theme → memory
- Privacy short-circuit · Phase 3 identity preservation · exit referential validation
- Frozen corpus `tarot_narrative_history_enrichment_v1.json` (55 scenarios · 44/44 classes)
- Storage→enricher shadow integration · delete/restart no-ghost
- Stop: enrichment closed-universe PASS; Phase 3 relationships unchanged · **IMPLEMENTED**

### 4D.1 — Enrichment privacy contract hardening · **IMPLEMENTED / PASS**

- H18: `currentOwnerId` + `privacyBlocked` required · no defaults · no inference from history
- Architecture signature matches production
- Stop: privacy argument non-optional · **IMPLEMENTED**

### 4E — Independent red-team / final audit

- Mirror 3D.1E style audit  
- Stop: READY FOR later user-path review (still shadow unless approved)  

---

## 23 — Acceptance corpus plan (minimum classes)

Count target: **≥28** frozen scenarios covering:

no history · one prior same card · multi prior · outside 90d · current excluded · deleted absent · different orientation · different spread · context overlap T/F · >5 occurrences · >20 prior Tarot · two types same theme · same type only · three types · irrelevant theme · explicit recall · empty question · TR/EN/RU · owner A/B · malformed legacy · missing positionKey · history clear · restart after delete · current theme echo without history · memory >800 input · >4 theme candidates · same-timestamp tie

---

## 24 — Evidence id namespaces (LOCKED)

| Kind | Format |
|---|---|
| relationship (Phase 3) | `rel_##` |
| memory | `mem_##` |
| recurring card | `rec_card_##` |
| recurring theme | `rec_theme_##` |

---

## 25 — Spec readiness

| Gate | Status |
|---|---|
| Canonical Tarot history strategy | LOCKED (A) |
| Dedupe key | LOCKED |
| Owner / ownerless policy | LOCKED |
| Completed criteria | LOCKED |
| 90-day boundary | LOCKED (≤ 90d) |
| Card recurrence semantics | LOCKED |
| Context overlap | LOCKED |
| Memory authority | LOCKED (OraclyMemory) |
| Cross-feature theme (≥2 types) | LOCKED |
| Theme map / relevance | LOCKED |
| recentCardNames / recurringThemeLabels | LOCKED empty |
| Memory model amendment | LOCKED YES (additive) · **4B** |
| Enrichment architecture | LOCKED |
| Delete coupling required in 4C | LOCKED · **IMPLEMENTED** |
| OPEN decisions | **0** |

**Phase 4A: IMPLEMENTED** (pure card recurrence · no storage · no user path)
**Phase 4A.1: IMPLEMENTED** (identity / generic-topic / aşk hardening)
**Phase 4B: IMPLEMENTED** (theme + memory pure engines · no storage adapters)
**Phase 4C: IMPLEMENTED** (storage adapters · owner isolation · source-existence · delete/clear integrity)
**Phase 4C.1: IMPLEMENTED** (H14 owner-safe live Tarot ids · H15 typed memory delete · H16 question grounding fallback)
**Phase 4C.2: IMPLEMENTED** (H17 strict live Tarot source aliases — no linked.sessionId authority)

**Do not start 4D until ChatGPT review. Do not merge. Do not wire user path.**
