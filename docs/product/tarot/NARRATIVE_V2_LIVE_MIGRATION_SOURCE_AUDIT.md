# Narrative V2 — Live Migration Source Audit (Phase 6.0)

**Phase:** 6.0 · **Kind:** FORENSIC / AUDIT-ONLY · **Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Worktree:** `D:/oracly_final_r1`  
**START HEAD:** `4b56592bc9dc2fea9bb75416851844cc18731891`  
**Production / tests / fixtures changed:** **NONE**

**Independent Phase 5 re-freeze (recorded here as project state):**  
ChatGPT verified Phase 5F.1 at `4b56592bc9dc2fea9bb75416851844cc18731891`.  
**PHASE 5 — SIGNATURE SPREADS RE-FROZEN AFTER 5F.1 INDEPENDENT VERIFICATION.**

Phase 3 · Phase 4 · Phase 5 remain **FROZEN**. Crossroads: shadow-only · picker **false** · live Narrative V2 **NOT WIRED**.

---

## 0 — Scope

Map the **currently user-reachable** Tarot interpretation pipeline and lock migration architecture **before any production wiring**.  
No implementation. No feature flags. No picker changes.

---

## 1 — Live user call graph (exact)

### Primary success path

```
ReadingScreen._loadInterpretation (presentation/screens/reading_screen.dart)
  → JourneyPersonalizationBuilder.fromHistory + optional memory + revisit
  → TarotReadingCompletion.complete (economy/tarot_reading_completion.dart)
       · affordance: TarotReadingCharge.canAfford
       · load: TarotReadingController.resolveInterpretationContent
            → TarotInterpretationService.generateContent
                 · SensitiveTopicGate.maybeRespond → emergencyFallback (no provider)
                 · ReadingContext.fromSession (+ journeyHints)
                 · InterpretationEngine.interpret
                      · cache.get(ReadingContext.cacheKey) short-circuit
                      · InterpretationPromptAdapter.attachPrompt (builds PromptRequest)
                      · executor.execute (AiInterpretationExecutor when configured)
                           → OraclyAiService.generateTarotReading
                           → OpenAiPaidRequests.tarotReading (proxy payload)
                           → parseAiResponse → InterpretationResult
                      · engine retry (maxAttempts=2) on retryable InterpretationException
                 · ReflectiveIntelligence.guard
                 · AiOutputQualityTarot.passes → optional forceRefresh retry
                 · InterpretationFormatter.toUiContent → AiReadingContent
       · on success + usable: markProviderOk → commit (gems)
  → updateSession(interpretation text)
  → setState(_contentData) → result UI
  → _persistToJournal → ReadingService.saveFromSession → HistoryRepository
```

### Failure / free points

| Point | Behavior |
|---|---|
| Empty drawn cards | `complete` returns null — no charge |
| Cannot afford | `complete` returns null — no provider call |
| Provider / timeout / quality fail (not already charged) | null / typed exception — **no spend** |
| Already charged + later fail / empty | `emergencyFallback` — recovery content, no second charge |
| `shouldCommit` false (unmounted / stale token) | null after usable content — **abandon** path if mark failed |
| Sensitive topic | `emergencyFallback` **before** engine — no provider, no charge if completion never marks |

### Gem commit boundary (locked fact)

Charge occurs **only after**:

1. Provider (or injectable `load`) returns  
2. `_usable(content)` (non-empty `generalMeaning` or `fullInterpretation`)  
3. `shouldCommit()` true  
4. `markProviderOk` then `commit`

Provider failure **before** mark → free. Idempotency key: `PaidAiOperationId.fromExisting('tarot', session.id)`.

---

## 2 — Entry-point classification

### `TarotInterpretationService.generateContent`

| Site | Class |
|---|---|
| `TarotReadingController.resolveInterpretationContent` ← live ReadingScreen via `TarotReadingCompletion` `load:` | **A — live user-reachable** |
| `TarotReadingCompletion.complete` default `load` when `interpretation` not injected | **B — footgun / unused on wired ReadingScreen** (live path always passes `load:`) |
| Tests | **C** |

### `generateResult` / `generateStream` / `regenerate` (service)

| Method | Production callers in `lib/` | Class |
|---|---|---|
| `generateResult` | **none** | **D — dead for live UI** (no quality gate on this API) |
| `generateStream` | **none** | **D** (`AiInterpretationExecutor.executeStream` → local only) |
| `regenerate` | **none** on Tarot service | **D** (other features’ `.regenerate` are unrelated controllers) |

### `InterpretationEngine.interpret` / `interpretStream`

| Site | Class |
|---|---|
| Via `TarotInterpretationService.generateContent` | **A** |
| Via `generateResult` / `generateStream` | **D** (no live callers) |

### `TarotReadingCompletion.complete`

| Site | Class |
|---|---|
| `ReadingScreen` interpretation load | **A** |
| (No other production callers found) | — |

### Quality-gate bypass risk

- Live success path **always** goes through `generateContent` → `AiOutputQualityTarot` (primary + `_qualityGatedContent` on retry).  
- `generateResult` / stream / engine cache hit **would** skip Tarot quality if ever wired — **must not** become live without the same gate.  
- `emergencyFallback` / sensitive-topic path **bypasses** quality by design (localized safety / recovery copy).

---

## 3 — Production DI / executor

### Wiring

| Layer | File | Behavior |
|---|---|---|
| Module | `tarot_module_root.dart` `_buildInterpretationService` | Reads `oraclyAiServiceProvider`; `allowLocalFallback: ai.allowsLocalFallback`; engine via `tarotInterpretationExecutorFor(ai)` |
| Selector | `tarot_interpretation_wiring.dart` | Unconfigured **and** `allowsLocalFallback` → `LocalInterpretationExecutor`; else → `AiInterpretationExecutor(ai:)` |
| Config | `ai_runtime_config.dart` | `allowsLocalFallback = !isConfigured && environment.isDevelopment && !_releaseLocked` |

### Exact answers

| Question | Answer |
|---|---|
| Production configured AI executor | **`AiInterpretationExecutor`** |
| Production unconfigured AI | Still **`AiInterpretationExecutor`** if release-locked / not development; calls fail → service fail-closed |
| Dev local fallback allowed | Only when **unconfigured** + **development** + not release-locked |
| Release local prose as success | **NO** (`allowLocalFallback` false → `_fallbackOrFail` throws) |
| Bare `TarotInterpretationService()` | Defaults `allowLocalFallback: true` + **Local** executor — used as `TarotReadingCompletion` / controller **defaults**; live module **overrides**. Must not appear on release user path without DI. |

**R2/R2.1 fail-closed guarantees: preserved by wiring + `allowLocalFallback` contract.**

---

## 4 — Retry / fallback state machine

### Engine (`InterpretationRetryPolicy.maxAttempts = 2`)

1. Optional cache hit → return (no provider)  
2. Attempt 1..2: `executor.execute` + timeout → validate summary + formatter  
3. Retryable `InterpretationException` → delay → retry  
4. Unexpected + offline → typed offline; else retry then fail  

### Service (`generateContent`)

1. Sensitive → emergency (stop)  
2. `interpret` → guard → quality  
3. Quality fail + !forceRefresh → `interpret(forceRefresh:true)` → quality  
4. Quality still fail → `_fallbackOrFail`  
5. On exception → `_retryOrFallback` (forceRefresh interpret → `_qualityGatedContent`) → `_fallbackOrFail`  
6. Fallback: local synthesize **iff** `allowLocalFallback`; else throw  

### Completion

```
afford? → load → usable? → shouldCommit? → markProviderOk → commit
              ↓ fail           ↓ no              ↓ commit fail
         alreadyCharged?    return null         abandon → null
              ↓ yes
         emergencyFallback
```

### Route audit (no code change)

| Risk | Current |
|---|---|
| Charge without usable result | **NO** (`_usable` before mark) |
| Provider failure as normal success | **NO** |
| Bypass quality on live generateContent | **NO** (except safety/emergency) |
| Double-charge | Guarded by settled op id + session id |
| Unexpected provider retry | Engine + service retries exist; binder key is session-scoped |
| Local prose success in release | **NO** |
| Emergency after committed charge | **YES** (intentional recovery) |

---

## 5 — What the AI actually receives (live)

### Critical split

`InterpretationEngine` **always** attaches `PromptRequest` via `InterpretationPromptAdapter`.  
**`AiInterpretationExecutor` does not read `promptRequest`.** Live provider path sends:

```
OpenAiPaidRequests.tarotReading payload:
  cards[{name, positionLabel, reversed, meaning, keywords}]
  spreadLabel
  userQuestion?
  readingTheme?
  journeyHints? {recurringThemes, recentCardNames, priorReadingCount, revisitExcerpt?, memorySummary?}
  language fields
```

Backend/proxy builds the model prompt from this payload. Client PromptEngine Tarot assembly is **not** the live transport body.

### Field classification (live payload + ReadingContext facts)

| Field | Class |
|---|---|
| Card names / positions / reverse / meanings / keywords | **A** deterministic (catalogue + draw) |
| Spread display label | **A** (current locale) |
| User question / theme | **A** (sanitized on wire) |
| `questionKind` (in PromptContext facts only) | **B** heuristic — **not** in live AI payload |
| Journey themes / prior count / memory summary / revisit | **C** historical / memory context |
| Card/position “relations” claimed in PromptContext `readingPipeline` string | **E** not supplied as structured evidence on live wire |
| Phase 3 relationships / evidence ids | **E** |
| Phase 4 recurrence evidence objects | **E** (only weak journeyHints) |
| Phase 5 Signature edges / spread id | **E** |

---

## 6 — Narrative V2 gap (Phases 3/4/5 → live)

| Frozen V2 surface | Live today |
|---|---|
| `TarotNarrativeRequest` (+ version) | **Absent** |
| `SpreadSemanticDefinition` / position ontology | Display labels only |
| Relationship evidence + kinds | **Absent** (AI free to invent) |
| Card evidence ids / ritual ids | **Absent** |
| Memory evidence bounds / omitReason | Weak `memorySummary` string |
| Recurring cards/themes evidence | Theme labels / counts only — **not** evidence-backed |
| Signature projection / Crossroads edges | **Absent**; shadow-only under `signature_spreads/` |
| Owner / privacyBlocked on request | **Absent** on live AI path |

**Duplicates / weaker twins:** journeyHints ≈ soft Phase 4 memory; catalogue meanings ≈ weaker than profiled narrative cards.  
**Contradiction risk:** PromptContext pipeline string advertises relations the wire does not send.  
**AI freedom to reduce:** relationship invention, recurrence claims, memory fabrication, fixed love/career/money forcing.

Live path **does not** call `NarrativeEvidenceBuilder`, `TarotNarrativeRequestEnricher`, or `SignatureSpreadShadowEvaluator` (grep: only under `signature_spreads` + narrative packages themselves).

---

## 7 — Result schema forensic

### `InterpretationResult` fields

summary · love · career · money · health · spiritualGuidance · advice · warnings · luckyEnergy · dailyFocus · closingMessage (+ meta)

### Usage

| Consumer | Uses |
|---|---|
| Quality | All non-empty fields via `AiOutputQualityTarot` |
| Formatter validate | summary nonempty + ≥3 filled sections |
| UI (`AiReadingContent`) | generalMeaning←summary, love, career, money, spiritual, lucky, dailyAdvice←dailyFocus, closing; health/warnings less central |
| Persist | `fullInterpretation` / session interpretation text |
| Journal | via `saveFromSession` after UI success |
| OR context | history/privacy titles + insight — not full section matrix |

### Product tension

Fixed life-area sections force love/career/money even for open / guidance / decision / Quick Insight / future Crossroads — **semantic mismatch risk** (documented, not redesigned in 6.0).

---

## 8 — Quality gate (`AiOutputQualityTarot`)

Per non-empty section: `AiOutputQualityGate.validate` + summary must be nonempty.

| Concern | Status |
|---|---|
| Non-empty / formatting | **SUPPORTED** |
| Certainty / medical / fear / legal / finance / love guarantees | **SUPPORTED** |
| Deterministic future | **SUPPORTED** |
| Fake memory / biography (text heuristics) | **SUPPORTED (WEAK vs V2 evidence)** |
| Robotic repetition | **SUPPORTED** |
| Card / spread / relationship grounding | **ABSENT** as structured checks |
| Memory accuracy vs evidence | **WEAK** (text heuristics; context flag optional) |
| Locale mixed-language | **SUPPORTED (WEAK)** |
| Response structure (section schema) | **WEAK** (formatter ≥3 sections, not kind-aware) |

---

## 9 — Cache forensic

`ReadingContext.cacheKey` =

`interp_{sessionId}_{shuffleSeed}_{questionHash}_{priorReadingCount}_{cardId:reversed…}`

| Distinguishes | Yes/No |
|---|---|
| Session / cards / reverse / question hash / prior count / seed | **YES** |
| Position keys / spread type / locale / journey text / memory / revisit / Narrative version / Signature id | **NO** |
| forceRefresh / regenerate | Bypasses read |

**Stale-cache risk if V2 lands without versioning:** **HIGH** — must bump cache identity with narrative version + evidence fingerprint.

Production module uses **`InMemoryInterpretationCache`** (process-local). Persisted `SharedPreferencesInterpretationCache` exists but is not the module-root default.

---

## 10 — Provider contract

| Item | Fact |
|---|---|
| Operation | `AiOperation.tarotReading` via proxy |
| Idempotency | Fingerprint from card name/position/reversed key; binder also keys session id |
| Response | Free-form chat text → `InterpretationFormatter.parseRawResponse` |
| Structured schema | **Not** enforced client-side |
| PromptEngine request | Attached but **unused** by AI executor |

V2 likely needs: **client payload change** + **backend/provider prompt change**; optional **structured response schema** (recommended).

---

## 11 — History save timing

1. Interpretation success + gem commit  
2. Session interpretation text updated  
3. UI content set  
4. `_persistToJournal` → `saveFromSession` (history + reading count)

**Required for Phase 6 correctness later:** narrative/result version + Signature spread id (machine).  
**Useful telemetry:** provider/model metadata, evidence provenance.  
**Do not add in 6.0.**

---

## 12 — Safety path

`SensitiveTopicGate.maybeRespond` in `generateContent` **before** engine:

- No provider call  
- Returns `emergencyFallback`  
- Completion may still see usable copy → **can charge** if treated as success  

**Phase 6 safety rule (locked in 6.0 architecture):** Safety responses **bypass Narrative V2**, must remain calm localized copy, and billing policy must treat safety-only responses as **non-billable** (explicit gate before `markProviderOk`) — **open minor** at 6.0 close; do not weaken detector.

---

## 12.1 — Phase 6.0.1 Safety Billing Remediation

**Kind:** PRODUCTION + TESTS + DOCS · **Date:** 2026-09-23  
**Trigger:** Independent ChatGPT verification of Phase 6.0 found a **CURRENT LIVE** billing/product defect (not invented by 6.0 docs).

### Independently confirmed root cause

Live path:

`ReadingScreen` → `TarotReadingCompletion.complete` → `resolveInterpretationContent` → `TarotInterpretationService.generateContent`

Inside `generateContent`, `SensitiveTopicGate.maybeRespond` returned usable `emergencyFallback` **before** the engine. Completion only checked usability, then:

`markProviderOk` → `commit`

So a safety-only local response could be charged as paid provider success, and `ReadingScreen._persistToJournal` could save it as a normal Tarot `ReadingModel` / memory source.

6.0 forensic **PASS** correctly mapped the call graph; it did **not** claim the live billing path already enforced non-billable safety. Post-audit independent review elevated this to **BLOCKER**.

### Remediation (6.0.1)

- Explicit `TarotReadingDeliveryKind` on `AiReadingContent` (`interpretation` / `safety` / `recovery`)
- Safety gate returns `deliveryKind: safety`
- Recovery fallback remains `deliveryKind: recovery` (no second charge; journal OK)
- Completion skips `markProviderOk` / `commit` for safety and recovery
- Controller does not persist safety prose into `ReadingSession.interpretation`
- ReadingScreen: no auto-journal; Save / Reflection / Ask Oracle / Share / Favorite disabled for safety
- Spec open minor “safety non-billable?” → **LOCKED YES**

**Do not rewrite history claiming 6.0 never found the risk** — 6.0 documented the charge boundary and left the flag as open minor; 6.0.1 closes the live defect.

---

## 13 — Crossroads seams A–L re-audit (independent)

| ID | Status | Evidence |
|---|---|---|
| **A** | **STILL VALID** | `NarrativeEvidenceValidation.resolveSpread` → `ClassicalSpreadSemantics.byLegacyTypeName` only |
| **B** | **STILL VALID** | Scorer/pairing uses `kAuthoritativePositionEdges`; Signature edges not consumed |
| **C** | **STILL VALID** | Crossroads structural edges exist in Phase 5 projection; no Phase 3 scoring path |
| **D** | **STILL VALID** | `classicalFromSpread` null/throws for non-classical (`crossroads`) |
| **E** | **STILL VALID** | Same-spread-alone forbid remains Phase 4/5 contract |
| **F** | **STILL VALID** | H7 identity — do not reopen casually |
| **G** | **STILL VALID** | H19 ordering — do not reopen casually |
| **H** | **STILL VALID** | privacyBlocked / owner / source existence |
| **I** | **STILL VALID** | Classical 1/3/5 shadow parity required |
| **J** | **STILL VALID** | Crossroads relationship QuestionKind unsupported |
| **K** | **STILL VALID** | `offeredInLivePicker=false` |
| **L** | **STILL VALID** | No release-readiness from Phase 5/6.0 alone |

Refinements for Phase 6: A/B/D become **implementation seams** (not obsolete). None obsolete.

---

## 14 — Live path firewall (6.0)

- No wiring · no flag · no picker · no provider/prompt/UI change  
- Phase 3/4/5 production: **unchanged**  
- Crossroads picker: **false** through Phase 6 until later approved gates (6 final + 7 visual + 8 E2E)

---

## 15 — Analyze / suite

`flutter analyze` (docs-only SHA): report in Phase 6.0 handoff.  
**FULL FLUTTER:** NOT RERUN — prior exact-code 5F.1 result at this HEAD: **4198 passed · 16 skipped · 0 failed**.

---

## 16 — Artifacts

Companion lock: `docs/product/tarot/NARRATIVE_V2_LIVE_MIGRATION_SPEC.md`
