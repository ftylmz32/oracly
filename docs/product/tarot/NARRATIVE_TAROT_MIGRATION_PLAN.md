# NARRATIVE TAROT MIGRATION PLAN

**Program:** ORACLY Narrative Tarot V2
**Document kind:** SAFE MIGRATION + PIPELINE BOUNDARIES (no runtime code)
**Depends on:** Phase 0 forensic baseline, Spec, Data Contract
**Status:** Phase 1 — **NOT IMPLEMENTED**

---

## 1. Reuse matrix

| Asset | Action | Notes |
|---|---|---|
| `OraclyTarotDeck` | **KEEP** | Canonical 78 identity |
| `OraclyTarotCard` | **KEEP** | Do not break catalogue |
| `OraclyTarotMeanings` | **ADAPT** | Seed + cite into `NarrativeCardProfile` |
| `OraclyTarotKeywords` | **KEEP** | Bridge into orientation profile |
| `OraclyTarotRelations` | **EXTEND** | Feed relationship evidence provenance |
| `OraclyTarotBridge` | **KEEP** | Ritual id ↔ canonical id |
| `TarotContentCatalogue` / `DeckService` | **KEEP** | Production draw path until unified |
| `TarotReadingEngine` | **ADAPT → REMOVE-LATER** | Reference for local synthesis; not V2 AI narrator |
| `ReadingStory` / `ReadingStoryWalk` | **ADAPT** | Deterministic beat seeds / length heuristics; retire as user-facing narrator after V2 |
| `ReadingRelations` | **ADAPT** | Candidate phrases → relationship evidence notes |
| `ReadingSlotSense` / `ReadingCardBeat` / `ReadingGuidance` / `ReadingHedge` / `ReadingAsk` / `ReadingQuestion` | **ADAPT** | Question kind, hedges, slot hints for evidence builder |
| `TarotIntention` | **KEEP / EXTEND** | Add kind mapping into `QuestionGrounding` |
| `ReadingContext` | **EXTEND** | Eventually wrap or map into `TarotNarrativeRequest` |
| `JourneyPersonalizationHints` | **EXTEND** | Feed memory evidence; add recurrence selector output |
| `TarotInterpretationService` | **EXTEND** | Boundary for fail-closed; later hosts narrative path |
| `InterpretationEngine` | **KEEP** | Retry policy container; may call new synthesizer |
| `AiInterpretationExecutor` | **REPLACE** (behavior) / **ADAPT** (transport) | Keep proxy AI call; change payload/result to narrative |
| `LocalInterpretationExecutor` | **KEEP** | Dev/`allowsLocalFallback` only — never production fake-success |
| `InterpretationResult` | **KEEP** + **LEGACY ADAPTER** | Persist old; project from V2 when needed |
| `AiReadingContent` | **KEEP** + **LEGACY ADAPTER** | Temporary UI bridge |
| `InterpretationFormatter` | **ADAPT** | Parse narrative schema; legacy markdown secondary |
| `ReadingPremiumBody` | **REPLACE LATER** | Narrative Result UI in Phase 6/7 |
| Ritual / fan / reveal | **KEEP** | Visual System extends; do not delete stacks yet |
| History / journal | **EXTEND** | Store v2 payload; reopen v1 |
| epic031 / parallel UI | **KEEP** then **REMOVE-LATER** | Inventory before Visual System |
| Dual asset roots | **KEEP** then unify in Visual System | No regeneration in Phase 1–3 |

**Do not delete anything in early phases.**

---

## 2. Proposed V2 pipeline

```text
Tarot session (draw complete)
  → SensitiveTopicGate (unchanged safety short-circuit)
  → NarrativeEvidenceBuilder          [DETERMINISTIC]
        load NarrativeCardProfiles
        resolve SpreadSemanticDefinition + positions
        build relationship candidates
        select verified memory / recurrence
  → TarotNarrativeRequest
  → NarrativeAiSynthesizer            [AI]
  → NarrativeQualityValidator         [DETERMINISTIC checks + quality gates]
  → TarotNarrativeResult (v2)
  → TarotReadingCompletion / charge   [EXISTING exactly-once]
  → Persistence (versioned)
  → Narrative Result UI (later)
       └─ LegacyUiAdapter (temporary)
```

| Stage | Deterministic | AI |
|---|---|---|
| Cards drawn / orientation / positions | YES | — |
| Profile + spread semantics attach | YES | — |
| Relationship candidates | YES | — |
| Recurrence counts / occurrence lists | YES | — |
| Memory include/omit | YES | — |
| Narrative prose | — | YES |
| Traceability beats metadata | AI fills refs; validator checks coverage | YES+YES |
| Quality fail-closed | YES | — |
| Settlement | YES (existing) | — |

**AI must not discover facts we can calculate locally** (counts, which cards, positions, stored recurrence).

---

## 3. Shadow validation

V2 must **not** immediately replace production.

| Gate | Intent |
|---|---|
| Feature boundary | Isolated narrative modules behind a future flag (specify only — **do not implement flag in Phase 1**) |
| Default validation | **Fixed offline corpus**, deterministic fixtures, explicit QA sessions, dedicated non-user tooling |
| Old-vs-new comparison | Human + automated anti-generic / anti-certainty on corpus |
| Quality gate | Extend gates for narrative fields + HARD referential integrity |
| Visual result | Phase 7 — not a precondition for shadow text validation |
| Production switch | Only after Phase 8–10 evidence **and** 78-profile completeness gate |

### Hard economy rule (Phase 1.1) — no live user double-call

Narrative V2 shadow validation **MUST NOT** silently double-call the AI provider during a **real user's paid Tarot reading**.

Default shadow validation uses:

- fixed offline corpus
- deterministic fixtures
- explicit QA sessions
- dedicated non-user validation tooling

A live shadow call is allowed **only** if explicitly designed as:

- non-user-facing
- **non-billed to user**
- budget-controlled
- telemetry-safe
- privacy-safe
- separately authorized by QA configuration

It must **never** create:

- double gem settlement
- double user charge
- duplicate persistence
- duplicate history entries
- hidden provider spend at uncontrolled scale

This is a **hard migration rule**.

---

## 4. Backward compatibility

| Concern | Rule |
|---|---|
| Old readings reopen | YES — v1 loaders unchanged |
| History list | YES — no mass rewrite |
| Schema stamp | New writes set `narrativeTarotVersion = 2` |
| Missing v2 fields on old rows | Treat as legacy; render via existing premium body |
| Adapter | `LegacyUiAdapter.fromNarrative(TarotNarrativeResult)` for interim UI |

---

## 5. Economy safety

Narrative V2 must **not** create:

- double settlement
- double AI charge
- duplicate reading save
- retry charging

**Authoritative:** existing `TarotReadingCompletion` + `TarotReadingCharge` + `PaidAiOperation*` exactly-once semantics.

Failed narrative quality / provider ⇒ null / exception ⇒ **no settle** (same as R2).

---

## 6. Failure semantics

Preserve **R2 / R2.1**:

| Case | Behavior |
|---|---|
| Provider failure after bounded attempts | `InterpretationException` / error UI + Retry |
| Quality failure after bounded attempts | fail-closed — **no** local canned success in production |
| `allowsLocalFallback == true` | local synthesis permitted (dev) |
| Safety gate | `emergencyFallback` unchanged |

V2 quality failure = **error/retry**, never fake successful reading.

---

## 7. Memory safety

Preserve **R1**:

- Clearing discovery / connected memory removes future Tarot influence from those sources.
- Account switch must not leak Tarot history or memory summaries.
- Recurrence scans only the **current account’s** stored readings.
- Deleted reading ids must disappear from recurrence evidence.

---

## 8. Implementation phase boundaries

| Phase | Scope | Notes |
|---|---|---|
| **2** | Quality corpus + acceptance harness | Fixed cases; metadata flags; no full UI redesign |
| **3** | Semantic profiles + deterministic Narrative Evidence Engine | Profiles layer; relationship builder; still may keep legacy AI path |
| **4** | Memory + Recurring Cards | Evidence structs; relevance; privacy tests |
| **5** | Signature Spreads | The Mirror + Between Us semantics + catalog integration |
| **6** | AI Narrative result pipeline + result data migration | Request/result, adapter, persistence version |
| **7** | Visual System + golden masters | Geometry hooks; goldens; unify chrome |
| **8** | Complete ritual E2E | Whole user ritual DoD |
| **9** | Red-team / destructive QA | Safety, flattery, fake recurrence, certainty |
| **10** | Full regression + release gate | Flutter + backend baselines |

### Recommended safer subdivision (optional)

If Phase 3 is too large, split:

- **3a** Profile model + completeness for Major only
- **3b** Evidence builder with classical spreads only
- **3c** Wire shadow synthesizer behind non-user path

Do **not** implement in Phase 1.

---

## 9. Architectural decisions (explicit)

### A. Semantic profiles vs `OraclyTarotCard`

**Decision:** Separate `NarrativeCardProfile` keyed by canonical card id.
**Rationale:** Phase 0 reuse without risky catalogue rewrites; incomplete profiles only in dev/migration/shadow.

**Production V2 completeness:** All **78** cards × release locales must pass the deterministic completeness gate before Narrative Tarot is the user path. Catalogue fallback is **not** a production success condition.

### B. Local narrative modules

| Module | Role |
|---|---|
| `ReadingStory*`, `ReadingRelations`, hedges, ask/question | **Reuse as deterministic seeds / reference** |
| `TarotReadingEngine` as user-facing production narrator | **Retire later** after V2 narrative ships |
| Prompt-only “readingPipeline” string | **Replace** with real evidence package |

### C. Deterministic vs AI boundary

**Deterministic:** facts, profiles attach, positions, relationships (+`evidenceId`), recurrence (+`evidenceId`), memory filter (+`evidenceRef`), quality/referential checks, settlement.
**AI:** narrative prose + beat text + optional recurringInsight wording **only if dedicated recurrence evidence present**.

### D. Where recurrence is calculated

**Locally**, in Narrative Evidence Builder / `RecurringCardSelector`, **before** AI.
AI never invents counts. Dedicated recurrence evidence is the only authority for recurrence claims.

### E. Legacy result coexistence

Keep `InterpretationResult` / `AiReadingContent`.
Add `TarotNarrativeResult` v2.
`LegacyUiAdapter` projects v2 → legacy for interim `ReadingPremiumBody`.
Remove adapter only after Narrative Result UI ships.

### F. UI independence

Domain result + beats metadata → UI mappers.
No business logic in widgets.
Internal evidence ids never render; share/export strips them.
`geometryHook` is data for Visual System, not copy.

### G. Signature spread integration

- Add `SpreadSemanticDefinition` entries with stable string ids: **`signature.the_mirror`**, **`signature.between_us`**.
- Persist spread id string on sessions going forward.
- Keep existing `TarotSpreadType` enum values for classical saved sessions.
- Mapping table: enum ↔ classical semantic ids; signatures are **additive**, not enum reuse of `fiveCard`.
- Do not reinterpret old `fiveCard` saves as The Mirror.
- Underscore aliases are **not** persisted ids.
- **Stable spread ids are immutable once persisted.**

### H. Localization

- Authored semantics: l10n / `L10nTriple`.
- AI body: request `languageCode`.
- Quality rejects mixed/wrong language bodies.
- Recurrence templates localized; numeric facts invariant.

---

## 10. Mapping from current production path

Current (Phase 0):

```text
ReadingScreen → TarotReadingCompletion → TarotInterpretationService
  → InterpretationEngine → AiInterpretationExecutor
  → guard → AiOutputQualityTarot → fail-closed
```

Target:

```text
ReadingScreen → TarotReadingCompletion → TarotInterpretationService
  → NarrativeEvidenceBuilder → Narrative synthesizer (via engine/executor)
  → NarrativeQualityValidator → fail-closed
  → TarotNarrativeResult → adapter/UI
```

Insert evidence builder **before** AI; keep completion/charge and ModuleRoot `allowsLocalFallback` wiring.

---

## 11. Exit criteria before production switch

- [ ] Phase 2 corpus green on narrative quality metadata + HARD referential integrity
- [ ] Recurrence false-positive tests green (dedicated evidence authority)
- [ ] **78-profile completeness gate green** for all release locales
- [ ] R1 privacy + R2/R2.1 fail-closed still green
- [ ] Legacy reopen tests green
- [ ] Economy exactly-once tests green (no live-user shadow double-call)
- [ ] Owner review of Narrative Result UX (Phase 6/7)
- [ ] Phase 8 ritual E2E + Phase 10 full suite

Until then: **Narrative Tarot Engine = NOT IMPLEMENTED** for users.
