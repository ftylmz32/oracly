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

## 12.2 — Phase 6.0.2 Independent Safety Purity Follow-up

**Kind:** PRODUCTION + TESTS + DOCS · **Date:** 2026-09-23  
**Trigger:** Independent ChatGPT verification of Phase 6.0.1 confirmed billing/journal fix, then found three follow-up defects.

### Findings (post-6.0.1)

| ID | Severity | Defect |
|---|---|---|
| **B1** | BLOCKER | Safety still used `emergencyFallback`, so `drawn.effectiveMeaning` polluted `generalMeaning` / life-area fields — fortune content despite free delivery |
| **M1** | MAJOR | Completion returned any usable `deliveryKind: recovery` without `alreadyCharged` — payment bypass risk |
| **M2** | MAJOR | `tarotContentWithSummary` dropped `deliveryKind` → silent reset to `interpretation` |

### Remediation (6.0.2)

- Dedicated `safetyResponse` builder — pure gate reason, empty card fields, no drawn cards
- `ReadingPremiumBody` safety branch — reason only; no story/cards/insight stack
- ReadingScreen skips journey-complete cue + reveal ceremony for safety
- Recovery authorized only when `alreadyCharged(session.id)`; else fail closed
- `tarotContentWithSummary` preserves `deliveryKind`
- Spec locks: pure safety · settled-only recovery · delivery kind survives copies

6.0.1 remains a correct billing/journal partial remediation; 6.0.2 closes purity + authorization + copy drift.

---

## 12.3 — Phase 6.0.3 Independent Safety Preflight Follow-up

**Kind:** PRODUCTION + TESTS + DOCS · **Date:** 2026-09-23  
**Trigger:** Independent ChatGPT verification of Phase 6.0.2 confirmed B1/M1/M2 closed, then found two remaining live defects.

### Findings (post-6.0.2)

| ID | Severity | Defect |
|---|---|---|
| **B2** | BLOCKER | Safety still behind `_charge.canAfford` — zero-balance sensitive users got null / insufficient-gems instead of free safety |
| **M3** | MAJOR | `ReadingQualityActions` still shown for safety; `_reinterpretWithoutCharge` wrote safety prose into `ReadingSession.interpretation` |

### Remediation (6.0.3)

- `safetyResponseIfNeeded` pure preflight; `generateContent` reuses it
- Completion order: empty guard → safety preflight → affordability → load
- Safety returns without invoking `load`
- Quality actions slot hidden for safety
- Defensive + post-resolve firewalls in `_reinterpretWithoutCharge`
- Spec locks safety ordering and no-version/no-interpretation writes

6.0.2 remains correct for B1/M1/M2; 6.0.3 closes affordability ordering + retry persistence.

---

## 13 — Crossroads seams A–L re-audit (independent)

| ID | Status | Evidence |
|---|---|---|
| **A** | **SEAM IMPLEMENTED (6A)** | `resolveSpread` → optional `NarrativeSpreadSemanticResolver` (default Classical); Signature adapter separate |
| **B** | **SEAM IMPLEMENTED (6A)** | Pairing/scorer/selector → optional `NarrativePositionEdgeProvider` (default Classical); Signature adapter separate |
| **C** | **STILL VALID** | Crossroads structural edges exist in Phase 5 projection; no Phase 3 full builder/scoring path yet |
| **D** | **SEAM IMPLEMENTED (6B)** | `classicalFromSpread(crossroads)` still null; `supportedFromSpread` → `signature.crossroads` historical FACT |
| **E** | **STILL VALID** | Same-spread-alone forbid remains Phase 4/5 contract |
| **F** | **STILL VALID** | H7 identity — do not reopen casually |
| **G** | **STILL VALID** | H19 ordering — do not reopen casually |
| **H** | **STILL VALID** | privacyBlocked / owner / source existence |
| **I** | **STILL VALID** | Classical 1/3/5 shadow parity required |
| **J** | **STILL VALID** | Crossroads relationship QuestionKind unsupported |
| **K** | **STILL VALID** | `offeredInLivePicker=false` |
| **L** | **STILL VALID** | No release-readiness from Phase 5/6.0 alone |

Refinements for Phase 6: A/B implemented (6A/6A.1). Seam D implemented (6B historical FACT). Seam C / full Crossroads Narrative remain later (6G). E–L preserved. None obsolete.

---

## 13.1 — Phase 6A implementation facts

**Date:** 2026-09-23 · **Kind:** Phase 3 narrow reopen · Classical-preserving

| Fact | Value |
|---|---|
| Spread resolver interface | `NarrativeSpreadSemanticResolver` + `ClassicalSpreadSemanticResolver` |
| Position edge provider | `NarrativePositionEdgeProvider` + `ClassicalPositionEdgeProvider` |
| Signature adapters | `SignatureNarrativeSpreadResolver` · `SignatureNarrativeEdgeProvider` (new files only) |
| Classical edge counts | single 0 · three 3 · five 6 · seven 8 · celtic 12 · **total 29** |
| Global edge table modified | **NO** |
| Default builder Crossroads | **UNSUPPORTED** (fails closed · no fiveCard fallback) |
| Phase3 → Signature imports | **NO** |
| Signature provider live callers | **0** |
| Phase 4 / Phase 5 SOT | **UNCHANGED** |
| Live Narrative V2 | **NOT WIRED** |
| Next | **Phase 6A.1** then **Phase 6B** |

6.0.3 independently verified before 6A.

**Classical parity (6A):** **PASS** (independent ChatGPT verification confirmed).

**Independent ChatGPT follow-up (post-6A):** Classical provider identity fail-closed defect — `edgesFor(signature.crossroads)` returned `[]` instead of rejecting incompatible spreads (indistinguishable from valid classical.single zero-edge).

---

## 13.2 — Phase 6A.1 provider identity hardening

**Date:** 2026-09-23 · **Kind:** fail-closed provider compatibility

| Fact | Value |
|---|---|
| Classical provider | Validates against `ClassicalSpreadSemantics.byLegacyTypeName` + spreadId/cardCount match |
| Signature provider | Validates against projected Crossroads identity + position-key set |
| Crossroads + Classical provider | **THROWS** (not empty) |
| Spoofed identities | **THROWS** |
| Default scorer/selector + Crossroads | **FAIL CLOSED** |
| classical.single | still returns **0** edges (valid) |
| Silent zero-edge Signature fallback | **NO** |
| Next | Independent 6A.1 verification → **Phase 6B** |

**Phase 6A / 6A.1 independently verified (ChatGPT).**

---

## 13.3 — Phase 6B Signature historical normalizer

**Date:** 2026-09-24 · **Kind:** Phase 4 narrow reopen · historical FACT only

| Fact | Value |
|---|---|
| Adapter | `SignatureHistorySpreadNormalizer` (new) |
| History helpers | `supportedFromSpread` · `supportedFromPersisted` |
| `classicalFromSpread(crossroads)` | still **null** |
| Crossroads historical `spreadId` | `signature.crossroads` |
| fiveCard fabrication | **NO** |
| H7 / H17 / H19 | **UNCHANGED** |
| Same-spread-alone recurrence | **UNCHANGED** (still false) |
| Current Crossroads builder | still **UNSUPPORTED** |
| Live Narrative V2 | **NOT WIRED** |
| Crossroads picker | **false** |
| Next | Independent 6B verification → **Phase 6C** |

**Phase 6B functional behavior independently verified (ChatGPT).**

**Independent follow-up:** broad `catch (_)` around Signature resolution silently converted invariant/programming failures into `null` / `skippedMalformed`.

---

## 13.4 — Phase 6B.1 Signature history resolver hardening

**Date:** 2026-09-24 · **Kind:** fail-visible Crossroads resolution

| Fact | Value |
|---|---|
| Broad catch removed | **YES** |
| Crossroads internal resolution errors silently swallowed | **NO** |
| Non-Signature `fromSpread` | still **null** (no throw) |
| Unknown persisted data | still fail-closed as **null** |
| Phase 4 production | **UNCHANGED** |
| Next | Independent 6B.1 verification → **Phase 6C** |

**Phase 6B.1 independently verified (ChatGPT).**

---

## 13.5 — Phase 6C Narrative prompt serializer + cache identity

**Date:** 2026-09-24 · **Kind:** dormant model-input infrastructure (no live wire)

| Fact | Value |
|---|---|
| Internal DTO | `NarrativeTarotPromptInput` |
| Serializer | pure `TarotNarrativeRequest` → DTO |
| Serializer version | **1** |
| Policy version | `narrative_policy_v1` |
| Canonical | sorted-key nested map + stable JSON |
| Cache identity | SHA-256 · `narrative_tarot_v2_s1_<hex>` |
| Evidence / source / owner / session / reading ids model-facing | **NO** |
| Live serializer call sites outside narrative | **0** |
| Backend / AI service / executor / live cache | **UNCHANGED** |
| Exact backend JSON field names | still **OPEN** for 6D |
| Live Narrative V2 | **NOT WIRED** |
| Next | Independent 6C verification → **Phase 6D** |

**Phase 6C independently verified (ChatGPT) for privacy / SHA-256 / bounds / locales / live call sites = 0.**

**Independent follow-up defects (not frozen):**

| ID | Gap |
|---|---|
| M1 | `interpretationOrder` not required to be exact permutation → silent card omit/dup |
| M2 | relationship card id vs position key correspondence not validated |
| M3 | `keyForInput` accepted mismatched narrative/serializer/policy versions under v2/s1 prefix |
| M4 | unsupported `languageCode` used TR fallback prose via `L10nTriple.of` |
| M5 | uncontracted `noteKeyOrText` copied into model-facing relationship DTO |

---

## 13.6 — Phase 6C.1 Narrative prompt structural integrity hardening

**Date:** 2026-09-24 · **Kind:** pre-freeze serializer contract fail-closed

| Fact | Value |
|---|---|
| M1–M5 remediated | **YES** |
| interpretationOrder | exact permutation of `0..cardCount-1` |
| relationship correspondence | card ↔ position required; self-pairs rejected |
| relationship note model-facing | **NO** (v1) |
| supported locales | exact `tr` / `en` / `ru` only |
| cache version namespace | narrative + serializer + policy validated before hash |
| Signature fixture | real Phase 5 Crossroads 5-card projection (TEST-ONLY) |
| False 1-card Crossroads fixture | **REMOVED** |
| Cache goldens changed | `privacy_sentinel_internal_ids`, `signature_manual_spread_generic` (2/8) |
| Serializer / policy version | still **1** / `narrative_policy_v1` |
| Live call sites | **0** |
| Next | Independent 6C.1 verification → **Phase 6D** |

**Phase 6C.1 M1–M5 independently verified (ChatGPT).**

**Independent follow-up defects (not frozen):**

| ID | Gap |
|---|---|
| M6 | TEST-ONLY Signature fixture mixed EN languageCode with RU `displayName` |
| M7 | model-facing numeric scalars (strength/relevance/confidence/counts) unvalidated |
| M8 | `request.bounds` could exceed `RequestBounds.defaults` and loosen prompt policy |

---

## 13.7 — Phase 6C.2 canonical bounds + scalar integrity + locale fixture

**Date:** 2026-09-24 · **Kind:** pre-freeze serializer boundary hardening

| Fact | Value |
|---|---|
| M6–M8 remediated | **YES** |
| Request bounds | `0 ≤ bound ≤ RequestBounds.defaults` |
| Relationship strength | finite `[0,1]` |
| Theme relevance / memory confidence | finite `[0,1]` |
| Recurrence coherence | `occurrenceCount > 0` and `≥ listed`; overlap/key locked |
| Theme supportCount | `≥ 2` |
| Signature fixture language | **EN** · `OraclyTarotDeck.name.of('en')` |
| Mixed-locale Signature golden | **NO** |
| Cache goldens changed | `signature_manual_spread_generic` (1/8) |
| Serializer / policy version | still **1** / `narrative_policy_v1` |
| Live call sites | **0** |
| Status | **6C.2 independently verified · Phase 6C FROZEN** |
| Next | **Phase 6D** |

---

## 13.8 — Phase 6D Narrative V2 wire + structured result contract

**Date:** 2026-09-24 · **Kind:** additive backend + dormant Flutter contracts (NOT live-wired)

| Fact | Value |
|---|---|
| Request mode | `narrative_v2` under operation `tarot_reading` |
| Request exact fields | `mode` · `contractVersion` · `language` · `narrative` |
| Narrative fields | Phase 6C canonical names (reused; no second representation) |
| Result contract version | **1** |
| Result exact top-level fields | `contractVersion` · `languageCode` · `summary` · `cardReadings` · `synthesis` · `relationshipInsights` · `recurringCardInsights` · `recurringThemeInsights` · `memoryInsights` · `lifeAreas` · `advice` · `reflectionPrompt` · `dailyFocus` · `closingMessage` |
| Provider schema | `oracly_tarot_narrative_v1` · `json_schema` · `strict: true` |
| Free-form markdown Narrative | **NO** |
| Backend evidence binding | **YES** |
| Flutter wire / parser / quality / bridge | **YES** (dormant packages) |
| `AiOutputQualityTarot` still required | **YES** |
| Legacy `{ text }` path | **UNCHANGED** |
| Live Narrative V2 wired | **NO** · call sites **0** |
| Exact JSON field-name minor | **RESOLVED** |
| Open minor remaining | life-area UI migration timing only |
| Status after ChatGPT verify | **NOT FROZEN** — M1 shallow inbound validation · M2 weak Narrative fingerprint |
| Next | **Phase 6D.1** |

---

## 13.9 — Phase 6D.1 backend input firewall + full semantic fingerprint

**Date:** 2026-09-24 · **Kind:** untrusted-client inbound hardening (backend only)

| Fact | Value |
|---|---|
| M1 remediated | **YES** — full enum/type/size/cross-field validation before provider |
| M2 remediated | **YES** — `tarot-narrative:<sha256>` over canonical full validated wire |
| Max Narrative JSON | **32000** chars (frozen 6C max observed **5385**) |
| Frozen 6C scenarios accepted | **8/8** |
| Current `spread.spreadId` | strict V1 machine ids only |
| Historical occurrence `spreadId` | V1 ids + Phase 4 legacy aliases (`single`, …) |
| Silent truncation | **NO** |
| Flutter production | **unchanged** |
| Live Narrative V2 | **NO** |
| Status | Independently verified · **FROZEN** |
| Next | **Phase 6E** (complete — see 13.10) |

---

## 13.10 — Phase 6E Classical dual-run shadow harness

**Date:** 2026-09-24 · **Kind:** deterministic migration shadow (no live cutover)

| Fact | Value |
|---|---|
| 6D / 6D.1 | Independently verified · **FROZEN** |
| Status after ChatGPT verify | **NOT FROZEN** — M1 broad catch · M2 shallow wire freeze · M3 parity early-exit → **6E.1** |
| Package | `lib/features/tarot/narrative/shadow/` (QA-only) |
| Launch Classical set | `single` · `threeCard` · `fiveCard` only |
| Launch corpus | **24/24 PASS** structural parity |
| Non-launch seven/celtic | **22/22** `notLiveLaunchCandidate` |
| Crossroads current reading | `notLiveLaunchCandidate` (6G) |
| Narrative construction | Phase 5 Classical path by reference (`SignatureSpreadShadowValidation` + `SignatureSpreadShadowClassical` + fingerprint). Signature product question-kind marketing gate for Quick Insight is **not** applied — live Classical single accepts all ReadingAsk kinds (Phase 3 corpus). |
| Legacy side | `ReadingContext.fromSession` facts only |
| Prose parity | **NOT required** (legacy meanings ≠ Narrative Evidence profiles) |
| Offline result assessor | parse → Narrative quality → bridge → ReflectiveIntelligence.guard → AiOutputQualityTarot |
| Offline corpus | **24/24** plumbing PASS — does **NOT** claim provider writing quality |
| Provider shadow manifest | `tarot_narrative_provider_shadow_manifest_v1.json` · **6** refs · max 6 calls/run |
| Real provider calls in 6E | **0** |
| Live Narrative V2 / billing / cache writes | **NO** |
| 6F authorized by 6E alone | **NO** — requires separate controlled real-provider shadow + independent review |
| Next | Independent 6E verification → **controlled real-provider shadow evaluation before 6F** |

---

## 13.11 — Phase 6E.1 shadow harness fail-loud + deep immutability + parity accuracy

**Date:** 2026-09-24 · **Kind:** QA harness hardening (shadow package only)

| Fact | Value |
|---|---|
| 6E corpus / offline / firewall | Independently verified |
| M1 remediated | **YES** — `on Object` removed; only `ArgumentError` → `serializationFailed` |
| M2 remediated | **YES** — recursive deep-freeze of `wirePayload` |
| M3 remediated | **YES** — parity card dimensions accumulate independently (no ritual early-exit) |
| Unexpected programming errors | fail loud (not swallowed) |
| Phase 5 orchestration | Classical components by reference; Quick Insight marketing Q-kind gate **not** applied to live Classical single migration |
| Phase 5 production | **unchanged** |
| Real provider calls | **0** |
| Next | Independent 6E.1 verification → **controlled real-provider Narrative shadow QA (max 6) — NOT 6F** |

---

## 13.12 — Phase 6E.2 controlled real-provider shadow (immutable evidence)

**Date:** 2026-09-24 · **Kind:** authorized QA (max 6 real calls) · evidence frozen

| Fact | Value |
|---|---|
| QA RUN HEAD | `3987f7a7851ba24b27ab58b36d3c0f2c3f04025b` |
| Execution | **PASS** · used **6** · remaining **0** · no retries · no billing/persistence |
| Structural / contract | **PASS** (backend + client parse + Narrative evidence + AiOutputQuality) |
| Provider writing quality | **NOT PASS** (independent ChatGPT review) |
| Immutable artifacts | `NARRATIVE_PROVIDER_SHADOW_QA_6E2.md` · `tarot_narrative_provider_shadow_results_6e2.json` · payloads · manifest **v1** |

### Independent finding classes

| ID | Class | Note |
|---|---|---|
| Q1 | Future certainty escaped automated gate | Call #4: “The future promises…” / “will lead to…” |
| Q2 | `memoryIndex` cannot represent multi-memory synthesis | Call #6 prose combined coffee+dream under index 0 |
| Q3 | Section repetition | summary/synthesis/advice/closing often restated |
| Q4 | Relationship epistemic overstatement risk | question ≠ partner mental-state evidence |
| Q5 | Native-language naturalness | TR/RU valid but sometimes stiff / translated-sounding |

**Distinction locked:** automated structural/safety PASS ≠ human provider-quality PASS.

---

## 13.13 — Phase 6E.3 Result Contract V2 + provider quality remediation

**Date:** 2026-09-24 · **Kind:** pre-live result contract + prompt/prose hardening · **0** provider calls

| Fact | Value |
|---|---|
| Request wire | still `mode=narrative_v2` · `contractVersion=1` · Phase 6C frozen |
| Result contract version | **2** |
| Provider schema | `oracly_tarot_narrative_v2` |
| Memory insight shape | `{ memoryIndices: int[], text }` · sorted · unique · globally non-reused |
| Old `memoryIndex` | **rejected** (fail closed · no silent migration) |
| Prose guard | `narrative_tarot_prose_quality` · `deterministicFuture` sentinels |
| Captured Call #4 | **FAIL** under new guard (required) |
| Prompt | future modality · no mind-reading · section jobs · optional lifeAreas · native TR/RU |
| Manifest v2 | `tarot_narrative_provider_shadow_manifest_v2.json` · 6 entries · **0** calls until NEW authorization |
| Enriched v2 case | `enrichedProviderQaRequest` (corpus displayName + enricherRichHistory) |
| Historical 6E.2 evidence | **unchanged** |
| Live Narrative / 6F | **NO** |
| Next | Independent 6E.3 verify → **request NEW authorization for Manifest V2 provider run** — NOT 6F |

---

## 13.14 — Phase 6E.3.1 backend prose-quality fail-loud hardening

**Date:** 2026-09-24 · **Kind:** narrow error-handling remediation · **0** provider calls

Independent ChatGPT verification of 6E.3 confirmed Result Contract V2, `memoryIndices`, prompt rules, Call #4 detection, and live firewall — but found one follow-up:

| Defect | Broad `try/catch` around `assertNarrativeProseQuality` in `narrative-tarot-result.ts` mapped **every** exception to `invalid_response`, including programming/invariant/`TypeError` failures |
| Remediation | Parser uses pure `findDeterministicFuture(narrativeVisibleProse(result), language)` — non-null → `invalid_response`; unexpected detector throws **propagate** (fail loud) |
| Pattern set | **unchanged** |
| Result / request contracts | **unchanged** (Request 1 · Result 2) |
| Prompt semantics | **unchanged** |
| Flutter production | **unchanged** |
| Manifest V2 / 6E.2 evidence | **unchanged** |
| Live Narrative / 6F | **NO** |
| Next | Independent 6E.3.1 verify → **request NEW authorization for Manifest V2 provider run** — NOT 6F |

---

## 13.15 — Phase 6E.4 Controlled real-provider Manifest V2 shadow QA

**Date:** 2026-09-24 · **Kind:** authorized real-provider QA · **6** calls used · **0** remaining

| Fact | Value |
|---|---|
| QA RUN HEAD | `6e2fa96ab1ca0bfc48f2ac7a84a3a6557a7dee92` |
| Manifest | V2 · 6 entries · unchanged |
| Precall | **PASS** (6/6) |
| Transport successes | **0 / 6** · all `provider_error` |
| Backend structured / client / AiQuality | **0** |
| Structured prose captured | **NONE** (typed failures only · not fabricated) |
| Likely cause (unfixed in-run) | OpenAI strict schema reject — `uniqueItems` on `memoryIndices` |
| Production modified during run | **NO** |
| Live / 6F | **NO** |
| Next | Schema remediation phase → **NEW** Manifest V2 authorization — NOT 6F |

Evidence: `NARRATIVE_PROVIDER_SHADOW_QA_6E4_V2.md` · `tarot_narrative_provider_shadow_results_6e4_v2.json`

---

## 13.16 — Phase 6E.4.1 OpenAI Structured Outputs schema compatibility + error observability

**Date:** 2026-09-24 · **Kind:** offline remediation · **0** provider calls

Independent root cause of 6E.4 (valid execution, failed before generation):

| Fact | Value |
|---|---|
| Defect | Provider JSON Schema used `uniqueItems: true` on `memoryIndices` |
| OpenAI Structured Outputs | `uniqueItems` **not** in supported array subset (`minItems`/`maxItems` are) |
| Fix | Removed `uniqueItems` from provider schema; added `maxItems = maxMemoryEntries` |
| Result Contract V2 semantics | **unchanged** — backend `parseMemory` + Flutter still reject duplicate / unsorted / global reuse |
| Observability | Non-OK provider HTTP now keeps bounded `httpStatus` · `requestId` · `providerMessage` on `ProxyError.details` |
| Client envelope | still `{ success:false, error:{ code } }` only — **no** providerMessage to Flutter |
| Schema failures | classified `invalid_request` (e.g. `invalid_json_schema`) |
| Historical 6E.4 / 6E.2 / Manifest V2 | **immutable** |
| Live / 6F | **NO** |
| Next | Independent 6E.4.1 verify → **repeat Manifest V2 provider shadow under standing continue instruction · fresh hard cap 6** — NOT 6F |

---

## 13.17 — Phase 6E.4.2 Clean Manifest V2 provider shadow rerun

**Date:** 2026-09-24 · **Kind:** authorized real-provider QA · **6** calls · Result Contract V2

| Fact | Value |
|---|---|
| QA RUN HEAD | `2799e9bf518b2e1db6e9ce338643bffef8c4e632` |
| Manifest V2 | unchanged |
| Precall / schema compat / outbound bodies | **PASS** · `uniqueItems` absent |
| Transport / backend structured | **6 / 6** |
| Client parse / Narrative quality / AiOutputQuality | **6 / 6** |
| Call #6 memoryIndices | `[0,1]` multi-memory synthesis |
| Deterministic-future automated hits | **0** |
| Historical 6E.4 artifacts | **immutable** |
| Production during run | **NO** |
| Live / 6F | **NO** |
| Writing quality | **pending ChatGPT** · agent does **not** claim PASS |

Evidence: `NARRATIVE_PROVIDER_SHADOW_QA_6E42_V2.md` · `tarot_narrative_provider_shadow_results_6e42_v2.json`

---

## 13.18 — Independent ChatGPT review of 6E.4.2 + Phase 6E.5 writing-quality refinement

**Date:** 2026-09-24 · **Kind:** independent prose review + prompt refinement · **REAL PROVIDER CALLS: 0**

### Independent 6E.4.2 verdict (ChatGPT)

| Gate | Verdict |
|---|---|
| Execution / transport / structured / client | **PASS** (6/6) |
| Q1 deterministic future | **PASS / RESOLVED** (Call #4 modal: potential / possibility / could / achievable) |
| Q2 memory provenance | **PASS / RESOLVED** (Call #6 `memoryIndices: [0,1]`) |
| Q3 section repetition | **NOT resolved** — Calls **#3 / #4 / #6** high/review-worthy; #1/#2/#5 lower |
| Q4 relationship epistemic / directness | **PARTIAL** — improved framing; Call **#5** needs more direct symbolic answer to “Что за чувства…” |
| Q5 native language | **PARTIAL** — TR improved; RU still needs idiomatic refinement |
| Provider writing quality | **NOT FROZEN** |

### Phase 6E.5 production change

| Fact | Value |
|---|---|
| Primary file | `backend/src/ai/narrative-tarot-prompt-rules.ts` |
| Contracts / schema / parser / transport / prophecy patterns | **unchanged** |
| Flutter production | **NONE** |
| Real provider calls | **0** |
| Production repetition regex gate | **NO** |
| QA-only distinctness tool | `tool/qa/narrative_section_distinctness.mjs` |
| Historical 6E.4.2 artifacts | **immutable** |
| Live / 6F | **NO** |
| Next | **Phase 6E.6** — clean real-provider V2 quality rerun (separate authorization) |

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
