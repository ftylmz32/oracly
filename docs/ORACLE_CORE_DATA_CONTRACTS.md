# ORACLE CORE — MVP Data Contracts

**Status:** Design only · No implementation  
**Version:** 0.1  
**Scope:** Data contracts for four Oracle Core concepts — not services, not storage, not UI  
**Hierarchy:** [RC-009](./RC-009.md) → [RC-010](./RC-010.md) → [RC-011](./RC-011.md) → **this contract**  
**Non-goals:** Feature work · new databases · parallel stores · changing existing models · copying live DTOs

---

> Oracle Core does **not** invent a second journey database.  
> It names the **minimum shared shape** that already-existing records and engines can project into — so Personal Discovery, Reflection, and Experience Orchestrator speak one vocabulary later.

---

## 0. Placement in the existing stack

```
Canonical source records (already persist)
  ReadingModel · ritual keys · coffee/palm/dream/... histories
  DiscoveryJournalEntry · AI conversations · journal metadata
        |
        v  read-only aggregation
IntelligenceLayerService / IntelligenceRepository          [RC-009]
        |
        v  observable patterns only
ReflectionEngineService -> ReflectionSummary                [RC-010]
        |
        v  decide what to surface (not what to store)
ExperienceOrchestratorService -> ExperienceContext          [RC-011]
        |
        v  FUTURE projection (not a new write path)
Oracle Core contracts (this doc)
  Experience · ThemeEvidence · Insight · NextAction
        |
        +-> Personal Discovery / Insights / Journal / Continuation (consumers)
```

**Rule:** Contracts are **derived views** or **in-memory session envelopes**.  
They are **not** a second persistence schema. Source of truth remains the canonical feature repositories.

**Naming collision (critical):**

| This doc | Existing type | Difference |
|----------|---------------|------------|
| `Experience` | RC-011 `ExperienceContext` | Contract = one completed user event. RC-011 = orchestrator **decision** DTO. |
| `Insight` | `Insight` / `PersonalInsight` / `CrossDiscoveryInsight` / RC-010 `GrowthInsight` | Contract = durable thematic understanding. Existing types are feature-local projections. |
| `ThemeEvidence` | `InsightEvidence` / `ReflectionEvidenceKind` / discovery signals | Contract = one observable link theme <-> source record. |
| `NextAction` | `DiscoveryRecommendation` / `SessionContinuation` / `ExperienceHighlight` | Contract = timed, gated recommendation with lifecycle timestamps. |

Do **not** rename or merge these today. Adapters project *from* existing types *into* contracts when implementation starts.

---

## 1. Shared vocabulary

### 1.1 Identifiers

| Field pattern | Type | Rule |
|---------------|------|------|
| `featureId` | `OraclyFeatureId` (existing enum) | Never free-form strings for live modules |
| `sourceRecordId` | `String` | ID of the **canonical** persisted record in that feature store |
| `experienceId` | `String` | Stable id for one Experience projection (may equal `sourceRecordId` or a deterministic composite) |
| `evidenceId` | `String` | Stable id for one ThemeEvidence row (deterministic preferred) |
| `insightId` | `String` | Stable id for one Insight projection |
| `nextActionId` | `String` | Stable id for one NextAction instance |

### 1.2 Enums (contract-level — not new storage enums until implementation)

**`ExperienceStatus`**

| Value | Meaning |
|-------|---------|
| `started` | Session opened; not yet meaningful completion |
| `completed` | User finished a real ritual/reading/observation |
| `abandoned` | Left before completion (optional; only if observable) |
| `suppressed` | Exists but must not feed personalization (privacy / delete / soft-hide) |

**`PremiumState`** (snapshot, not live entitlement lookup)

| Value | Meaning |
|-------|---------|
| `unknown` | Entitlement was not observed at event time |
| `free` | Not premium when the event completed |
| `premium` | Premium active when the event completed |

Maps from existing `PremiumService.isActive()` / `ExperienceOrchestratorInput.premiumActive` **at observation time only**. Never rewrite historical `premiumStateAtCompletion` when entitlement later changes.

**`EvidenceKind`** (align with RC-010; do not invent predictive kinds)

| Contract | Existing anchor |
|----------|-----------------|
| `themeTag` | `ReflectionEvidenceKind.themeTag` |
| `keyword` | `ReflectionEvidenceKind.keyword` |
| `cardDraw` | `ReflectionEvidenceKind.cardDraw` |
| `journalTopic` | `ReflectionEvidenceKind.journalTopic` |
| `spreadUsage` | `ReflectionEvidenceKind.spreadUsage` |
| `engagement` | `ReflectionEvidenceKind.engagement` |
| `crossFeature` | Discovery multi-source observation (Personal Discovery only) |

**`Confidence` / `Strength`**

ORACLY already uses **tier enums**, not floats (`DiscoveryThemeStrength`: observed / recurring / strong).

| Contract field | Allowed type | Forbidden |
|----------------|--------------|-----------|
| `confidence` | Tier enum compatible with `DiscoveryThemeStrength` **or** discrete 0-2 int | Continuous 0.0-1.0 "AI confidence" |
| `strength` | Same tier family | Predictive score, streak meter |

**`InsightState`**

| Value | Meaning |
|-------|---------|
| `emerging` | Few observations; soft language only |
| `recurring` | Repeated across time |
| `strong` | High occurrence + recency + multi-source (still observational) |
| `fading` | Was recurring; recent window quiet |
| `archived` | User-dismissed or privacy-suppressed |

**`NextActionReasonType`**

| Value | Meaning |
|-------|---------|
| `continueRitual` | Unfinished / today ritual |
| `deepenTheme` | Theme recurred; invite related chamber |
| `revisitMemory` | Journal / history reopen |
| `reflectWithOr` | OR follow-up (existing handoff) |
| `exploreAdjacent` | Soft adjacent feature (never FOMO) |
| `premiumRelevant` | Premium relevance only when honest (`PremiumRelevance`) |

**`PremiumGateState`** (for NextAction)

| Value | Meaning |
|-------|---------|
| `none` | Action available without premium |
| `softHint` | Premium relevant but not blocking |
| `gated` | Opening requires premium (must match live entitlement UX) |
| `unavailable` | Feature offline / flag off |

### 1.3 Privacy baseline (all four contracts)

Inherited from EPIC-014 / existing privacy paths:

- Local-first; no new cloud schema implied
- User deletion of a **source record** must cascade to projections
- Never store raw chat dumps or full interpretation markdown inside contracts
- Contracts carry **ids + short observational fields** only
- `suppressed` / `archived` honor history delete and privacy controls already wired

### 1.4 Lifecycle baseline

| Phase | Who owns it today | Oracle Core stance |
|-------|-------------------|--------------------|
| Write | Feature repositories | **Unchanged** — features keep writing their own models |
| Read / aggregate | RC-009 | Contracts projected on read |
| Pattern | RC-010 | ThemeEvidence / Insight feed from reflection + discovery |
| Decide | RC-011 | NextAction informs recommendations; does not replace `ExperienceContext` |
| Surface | Discovery / Insights / Continuation | Consumers only |

---

## 2. Contract: `Experience`

One **completed (or suppressible) user event** in a feature chamber — the atomic journey atom.

> Not RC-011 `ExperienceContext`. Not a UI session controller.  
> Projection over an existing source record (e.g. `ReadingModel.id`).

### 2.1 Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `experienceId` | `String` | **required** | Stable; prefer `sourceRecordId` or `{featureId}:{sourceRecordId}` |
| `featureId` | `OraclyFeatureId` | **required** | Canonical module |
| `sourceRecordId` | `String` | **required** | FK-like to feature store row |
| `occurredAt` | `DateTime` | **required** | Completion time (document per-feature if only startedAt exists) |
| `status` | `ExperienceStatus` | **required** | Default projection: `completed` for persisted readings |
| `premiumStateAtCompletion` | `PremiumState` | **required** | Snapshot; `unknown` allowed for backfill |
| `topic` | `String?` | optional | From intention / reading type only — never invented |
| `spreadOrMode` | `String?` | optional | Spread title / palm hand / coffee mode — from source only |
| `hasUserNote` | `bool` | optional | From journal metadata if present |
| `schemaVersion` | `int` | **required** | Contract version for projections |

### 2.2 Source record relationship

| Feature | Canonical source | `sourceRecordId` | `occurredAt` |
|---------|------------------|------------------|--------------|
| Tarot | `ReadingModel` | `reading.id` | `createdAt` |
| Daily ritual | ritual date key / reading if any | date key or reading id | day boundary |
| Coffee / Palm / Dream / Astrology / Star map | feature history models | feature reading id | createdAt |
| OR chat | conversation id (if persisted) | conversation id | updatedAt / createdAt |
| Discovery Journal row | `DiscoveryJournalEntry` | `entry.id` | `date` |

**MVP:** one source record -> at most one primary Experience (1:1).

### 2.3 Lifecycle

```
source written -> (later) projected as Experience(status: completed)
user deletes source -> Experience status -> suppressed OR projection removed
entitlement changes later -> premiumStateAtCompletion DOES NOT change
```

### 2.4 Privacy

- No full AI text, no card image blobs, no gem economy fields
- Intention / question: omit from Experience MVP (keep on source; Insights/OR handoff use privacy helpers)

### 2.5 Premium

- Capture `premiumStateAtCompletion` once when projecting a completed event (if known)
- Backfill historical rows as `unknown`
- Orchestrator continues to use **live** `premiumActive` for decisions

### 2.6 Test requirements

| Test | Assert |
|------|--------|
| Identity | Same source always yields same `experienceId` |
| Feature binding | `featureId` matches store kind |
| No invention | Missing topic/spread stays null |
| Delete cascade | Deleted reading -> no active Experience projection |
| Premium snapshot | Changing live premium does not rewrite past `premiumStateAtCompletion` |
| Not RC-011 | Contract fields do not include greeting/recommendation blobs |

---

## 3. Contract: `ThemeEvidence`

One **observable** link between a theme and a source event.

> Closest living ideas: RC-010 evidence kinds + Personal Discovery theme signals + `InsightEvidence`.

### 3.1 Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `evidenceId` | `String` | **required** | Deterministic preferred: `{theme}|{experienceId}|{evidenceKind}` |
| `theme` | `String` | **required** | Canonical theme id/label (single registry chosen at implementation) |
| `experienceId` | `String` | **required** | Parent Experience |
| `sourceFeature` | `OraclyFeatureId` | **required** | Denormalized from Experience |
| `sourceRecordId` | `String` | **required** | Same as Experience source |
| `observedAt` | `DateTime` | **required** | Usually Experience.`occurredAt` |
| `evidenceKind` | `EvidenceKind` | **required** | Observable class only |
| `confidence` | tier enum | **required** | Start at `observed`; upgrade via Insight aggregation, not LLM |
| `note` | `String?` | optional | Short crumb (<= ~120 chars); never full reading |
| `schemaVersion` | `int` | **required** | |

### 3.2 Source record relationship

```
ThemeEvidence --N:1--> Experience --1:1--> source record
```

No orphan ThemeEvidence without a surviving source (unless Experience is `suppressed` and evidence is also suppressed).

### 3.3 Lifecycle

```
Experience completed
  -> extractors (PersonalThemeExtractor / RC-010 analyzers / journal tags)
  -> ThemeEvidence rows (in-memory or derived index — NOT a new user DB)
Insight aggregation consumes many ThemeEvidence
source deleted -> evidence suppressed with Experience
```

### 3.4 Privacy

- Theme labels only from existing lexicons / user-visible tags
- No private question text in `note`
- Cross-feature evidence only when both sources are user-owned local records

### 3.5 Premium

- ThemeEvidence itself is **not gated**
- Premium may affect which experiences exist, not whether evidence is "true"

### 3.6 Test requirements

| Test | Assert |
|------|--------|
| Observable only | No evidence without concrete source field |
| Determinism | Same inputs -> same `evidenceId` |
| Kind alignment | Kinds map to RC-010 taxonomy (+ optional `crossFeature`) |
| Confidence tier | Never a continuous probability |
| Cascade | Source delete removes/suppresses evidence |
| No dump | `note` length capped; no full interpretation |

---

## 4. Contract: `Insight`

Accumulated **observational** understanding of a theme across evidence — never a fortune.

> Closest aggregates: RC-010 `RecurringTheme`, Personal Discovery `CrossDiscoveryInsight` / `PersonalInsight`, domain `PersonalInsightReport`.

### 4.1 Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `insightId` | `String` | **required** | Prefer theme-stable id (one active Insight per theme for MVP) |
| `theme` | `String` | **required** | Same registry as ThemeEvidence |
| `evidenceIds` | `List<String>` | **required** | Non-empty for non-archived; may be capped (last N) |
| `sourceFeatures` | `List<OraclyFeatureId>` | **required** | Distinct features seen in evidence |
| `occurrenceCount` | `int` | **required** | Must be >= 1 when active |
| `lastObservedAt` | `DateTime` | **required** | Max evidence `observedAt` |
| `firstObservedAt` | `DateTime` | optional | Min evidence `observedAt` |
| `strength` | tier enum | **required** | Align Discovery / RC-010 language |
| `state` | `InsightState` | **required** | emerging / recurring / strong / fading / archived |
| `summaryLine` | `String?` | optional | Short observational copy from existing presenters |
| `schemaVersion` | `int` | **required** | |

### 4.2 Source record relationship

```
Insight --1:N--> ThemeEvidence --> Experience --> source records
```

MVP: Insight never points at source records directly (keeps privacy + delete cascade simple).

### 4.3 Lifecycle

```
>=1 ThemeEvidence -> Insight(state: emerging)
repeat / multi-feature -> recurring / strong
quiet window -> fading (RC-010 PersonalTrend spirit)
user dismiss / privacy -> archived
recompute on read (preferred) OR light index — still not a parallel journey DB
```

### 4.4 Privacy

- Derived only; deleting sources must lower counts / archive
- No predictive language in `summaryLine` (EPIC-013)
- Do not attach full reading bodies

### 4.5 Premium

- Computing Insight is free/local
- **Surfacing** may follow premium / flags via RC-011 — presentation, not Insight truth

### 4.6 Test requirements

| Test | Assert |
|------|--------|
| Evidence integrity | Every `evidenceId` resolves or Insight rebuilt without orphans |
| Count honesty | `occurrenceCount` matches observable evidence policy |
| Multi-source | `sourceFeatures` lists only real contributing features |
| Non-predictive | Strength/state never imply prophecy |
| Fade/archive | Quiet windows and delete paths covered |
| Dual-stack warning | Mapping from RC-010 **and** Personal Discovery documented without claiming identical classes |

---

## 5. Contract: `NextAction`

A **time-bound, honest recommendation** to enter a feature — optional, calm, non-FOMO.

> Closest living ideas: `DiscoveryRecommendation`, `SessionContinuation`, RC-011 `ExperienceHighlight` / `RecommendationContext`.

### 5.1 Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `nextActionId` | `String` | **required** | Instance id (not theme id) |
| `recommendedFeature` | `OraclyFeatureId` | **required** | Target chamber |
| `reasonType` | `NextActionReasonType` | **required** | Why this exists |
| `evidenceIds` | `List<String>` | **required** | Empty only for documented reasons (e.g. `continueRitual`) |
| `generatedAt` | `DateTime` | **required** | Creation |
| `expiresAt` | `DateTime` | **required** | Soft expiry; calm, not countdown UX |
| `shownAt` | `DateTime?` | optional | First time surfaced to UI |
| `openedAt` | `DateTime?` | optional | User opened target |
| `completedAt` | `DateTime?` | optional | Related Experience completed after open |
| `dismissedAt` | `DateTime?` | optional | User dismissed |
| `premiumGateState` | `PremiumGateState` | **required** | Honesty with entitlement |
| `relatedInsightId` | `String?` | optional | If reason is theme-deepening |
| `copyKey` | `String?` | optional | i18n key only — UI owns strings |
| `schemaVersion` | `int` | **required** | |

### 5.2 Source record relationship

```
NextAction --> evidenceIds -> ThemeEvidence -> Experience -> source
          +-> recommendedFeature -> OraclyFeatureId / navigation registry
```

Opening uses existing navigation (`OraclyNavigationService`, Discovery Journal opener, Tarot module) — **no new router**.

### 5.3 Lifecycle

```
generated (from Insight / ritual / continuation)
  -> shownAt when UI displays
  -> openedAt when user navigates
  -> completedAt when a new Experience in recommendedFeature lands (optional)
  -> dismissedAt on explicit dismiss OR soft-expire without pressure
expiresAt passed + not opened -> inert (do not nag)
```

**Never:** streaks, countdowns, fear copy, fake urgency (EPIC-011 / OOS).

### 5.4 Privacy

- Carry evidence ids, not private payloads
- OR handoff remains existing `OracleReadingContext` / `OrChatHandoff` when `reasonType == reflectWithOr`

### 5.5 Premium

| `premiumGateState` | Behavior |
|--------------------|----------|
| `none` | Open freely |
| `softHint` | Show action; premium is contextual aside |
| `gated` | Must match live Premium UX — no dead CTA (PRINCIPLE-001) |
| `unavailable` | Do not show |

Evaluated at **generate/show** time from live entitlement — not a historical forensic field like Experience.`premiumStateAtCompletion`.

### 5.6 Test requirements

| Test | Assert |
|------|--------|
| Expiry | Expired actions not re-pressed as urgent |
| Gate honesty | `gated` never appears as tappable without premium path |
| Evidence policy | Reasons that require evidence fail closed if empty |
| No FOMO | No streak/countdown fields on contract |
| Navigation | `recommendedFeature` resolves via existing feature registry |
| OR path | `reflectWithOr` uses existing handoff only |
| Lifecycle | `dismissedAt` vs `completedAt` rules tested |

---

## 6. Cross-contract invariants

1. **No parallel store:** Mappers/projectors over RC-009 + Discovery/Insights — not duplicate SharedPreferences for `ReadingModel`.
2. **Observable only:** ThemeEvidence / Insight never claim future outcomes (EPIC-013 / RC-010).
3. **Delete is sacred:** Source delete => Experience suppressed => Evidence suppressed => Insight recomputed => NextAction evidence invalidated.
4. **Premium duality:** Historical snapshot on Experience != live gate on NextAction.
5. **One vocabulary for feature ids:** Always `OraclyFeatureId`.
6. **RC-011 stays the decision brain:** NextAction may feed recommendation deciders later; it does not replace `ExperienceContext`.
7. **Two Insight stacks remain until an adapter exists:** Do not delete Personal Discovery or RC-010 models in contract phase.

---

## 7. Integration map (existing files)

### 7.1 Experience <- sources

| Integrate with | Path | How |
|----------------|------|-----|
| Readings | `lib/core/domain/models/reading.dart` | Primary Experience for tarot |
| Journal meta | `lib/core/domain/models/ritual_journal_metadata.dart` | `hasUserNote`, tags -> later evidence |
| Intelligence aggregate | `lib/core/intelligence/services/intelligence_layer_service.dart` | Batch project from `getReadings()` |
| Intelligence repo | `lib/core/intelligence/domain/repositories/intelligence_repository.dart` | Read path only |
| Ritual history | `lib/core/intelligence/data/ritual_history_reader.dart` | Ritual Experiences |
| Journal timeline | `lib/features/discovery_journal/models/discovery_journal_entry.dart` | Multi-feature Experience index |
| Feature id | `lib/core/modules/oracly_feature_id.dart` | `featureId` |
| Premium live | `lib/core/services/premium_service.dart` | Fill `premiumStateAtCompletion` when known |
| Orchestrator input | `lib/core/experience/domain/models/experience_orchestrator_input.dart` | Shares premium vocabulary — do not conflate types |

### 7.2 ThemeEvidence <- extractors

| Integrate with | Path | How |
|----------------|------|-----|
| RC-010 evidence kinds | `lib/core/reflection/domain/models/reflection_evidence_kind.dart` | Kind enum alignment |
| Recurring themes | `lib/core/reflection/domain/models/recurring_theme.dart` | Expand into evidence list |
| Theme analyzer | `lib/core/reflection/engine/analyzers/recurring_theme_analyzer.dart` | Producer |
| Tarot lexicon themes | `lib/core/domain/models/personal_insight_theme.dart` | Theme id registry candidate |
| Discovery themes | `lib/features/personal_discovery/models/discovery_theme.dart` | Alternate registry — needs single adapter |
| Theme signals | `lib/features/personal_discovery/models/discovery_theme_signal.dart` | Strength tiers |
| Theme extractor | `lib/features/personal_discovery/services/personal_theme_extractor.dart` | Evidence producer |
| Insights evidence | `lib/features/insights/models/insight_evidence.dart` | Shape reference (do not copy) |

### 7.3 Insight <- aggregates

| Integrate with | Path | How |
|----------------|------|-----|
| RC-010 summary | `lib/core/reflection/domain/models/reflection_summary.dart` | Pattern root |
| RC-010 trends | `lib/core/reflection/domain/models/personal_trend.dart` | fading / rising mapping |
| Domain report | `lib/core/domain/models/personal_insight_report.dart` | Tarot-lexicon echoes |
| Insight engine | `lib/features/insights/services/personal_insight_engine.dart` | Producer A |
| Discovery insights | `lib/features/personal_discovery/models/cross_discovery_insight.dart` | Producer B |
| Discovery personal insight | `lib/features/personal_discovery/models/personal_insight.dart` | confidence-as-tier |
| Journey snapshot | `lib/features/insights/models/personal_journey_snapshot.dart` | Counts / honesty |
| Journey service | `lib/features/insights/services/personal_journey_service.dart` | Facade |
| Memory themes | `lib/core/intelligence/domain/models/memory_theme_stat.dart` | Frequency/recency |

### 7.4 NextAction <- recommendations / continuation

| Integrate with | Path | How |
|----------------|------|-----|
| Discovery recommendation | `lib/features/personal_discovery/models/discovery_recommendation.dart` | Closest MVP shape |
| Recommend engine | `lib/features/personal_discovery/services/discovery_recommendation_engine.dart` | Generator |
| Recommended feature | `lib/features/personal_discovery/models/discovery_recommended_feature.dart` | `featureId` bridge |
| Session continuation | `lib/core/continuation/models/session_continuation.dart` | Post-session NextAction |
| RC-011 recommendations | `lib/core/experience/domain/models/recommendation_context.dart` | Highlight ranking consumer |
| Recommendation decider | `lib/core/experience/engine/deciders/recommendation_decider.dart` | Decision hook |
| Orchestrator service | `lib/core/experience/services/experience_orchestrator_service.dart` | Future: emit/consume NextAction |
| Navigation | `lib/core/navigation/oracly_navigation_service.dart` | `openedAt` path |
| OR handoff | `lib/features/companion/services/or_chat_handoff.dart` + `OracleReadingContext` | `reflectWithOr` |
| Premium relevance | RC-011 `PremiumRelevance` | `premiumGateState` |

### 7.5 Docs / rules to respect when implementing later

| Doc / rule | Constraint |
|------------|------------|
| `docs/RC-009.md` | No AI writes; read-only aggregation |
| `docs/RC-010.md` | Observable patterns only |
| `docs/RC-011.md` | UI never owns business decisions |
| `docs/EPIC-012.md` | Journey = memory, not stats/streaks |
| `docs/EPIC-013.md` | No certainty / prediction language |
| `docs/EPIC-014.md` | Transparency + user ownership of data |
| `docs/EPIC-011.md` | Daily ritual: no FOMO / countdowns |
| PRINCIPLE-001 | No dead CTAs on gated actions |

---

## 8. Suggested later implementation order (still not this task)

1. **Mappers only:** `ReadingModel` -> `Experience` projector (unit tests)
2. **ThemeEvidence** from existing tags/analyzers (no new prefs keys)
3. **Insight** as pure function over evidence lists (compare to RC-010 + Discovery outputs)
4. **NextAction** adapter around `DiscoveryRecommendation` + `SessionContinuation`
5. Wire RC-011 decider to *read* NextAction — only when flags allow

Each step keeps **zero parallel persistence** until a deliberate RC allows an index cache (like existing `intelligence_index_store.dart` — metadata only).

---

## 9. Explicit refusals (contract phase)

| Do not | Why |
|--------|-----|
| New SQLite / Firebase collections for these four types | Violates "no new database" |
| Clone `ExperienceContext` fields into `Experience` | Different concepts |
| Float confidence scores | Conflicts with Discovery tier model + reflective honesty |
| Streak / points fields on NextAction | EPIC-011 / OOS |
| Store full OR / Tarot transcripts on contracts | Privacy + prompt-min rules |
| Rewrite existing models to "become" these contracts in-place | Out of scope; adapters first |

---

## 10. Acceptance checklist for a future implementation PR

- [ ] No new user-facing feature shipped under "Oracle Core" alone
- [ ] No new persistence schema without an RC amendment
- [ ] Existing models unchanged (or only additive adapters in new files)
- [ ] All four contracts covered by unit tests listed above
- [ ] Delete/privacy cascade tested for Tarot reading at minimum
- [ ] Premium snapshot vs live gate distinguished in tests
- [ ] RC-009 -> 010 -> 011 import direction preserved (no UI -> engine writes)

---

*End of design. Implementation requires an explicit follow-up task.*