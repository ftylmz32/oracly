# Narrative V2 — Live Migration Spec (Phase 6.0 Architecture Lock)

**Phase:** 6.0 · **Kind:** SPEC / ARCHITECTURE LOCK · **Date:** 2026-09-23  
**Baseline HEAD:** `4b56592bc9dc2fea9bb75416851844cc18731891`  
**Companion audit:** `NARRATIVE_V2_LIVE_MIGRATION_SOURCE_AUDIT.md`  
**Implementation in 6.0:** **FORBIDDEN**

Phase 5 status: **RE-FROZEN** after independent 5F.1 verification.

---

## 1 — Non-negotiable invariants

### Structural parity (classical live)

Must not change without explicit approval:

- Card identity · reversal · position · question · locale  
- Charge semantics · retry fail-closed · history identity · owner/privacy  

### Prose parity

AI prose is **non-deterministic**. Phase 6 requires **structural / evidence / billing** parity — **not** byte-identical prose.

### Billing

- Provider failure before valid completion → **no spend**  
- One reading → at most one successful charge  
- Retry / cache must not double-charge  
- Cancelled UI (`shouldCommit` false) must not commit  
- V2 validation failure ≠ billable success  
- Safety-only copy must not silently become a normal paid success without an explicit rule  

**Commit boundary:** Narrative V2 validation + quality must complete **before** `markProviderOk` / `commit`.

### Crossroads

Picker remains **false** until Phase 6 final audit + Phase 7 visual + Phase 8 ritual E2E approval — even if internal Narrative can process Crossroads earlier.

---

## 2 — Prompt migration architecture (LOCKED)

### Choice: **C — `NarrativeTarotPromptInput` + legacy adapter during migration**

| Option | Verdict |
|---|---|
| A Replace `TarotPromptInput` entirely | Rejected — no rollback surface; couples classical cutover |
| B Extend `TarotPromptInput` in place | Rejected — conflates free-form UI facts with evidence contract |
| **C New Narrative input + legacy adapter** | **Accepted** |

### Why C

- Rollback: feature slice can keep legacy `AiInterpretationExecutor` payload builder  
- Testability: serialize `TarotNarrativeRequest` → prompt payload in pure tests  
- Privacy: evidence ids stay internal; only bounded prose/facts leave device  
- Gradual: classical dual-run before cutover; Crossroads later  
- Cache: new identity includes `narrativeTarotVersion`  
- Honest about today: live path already **ignores** client PromptEngine assembly — migration owns the **proxy payload**, not only PromptEngine templates  

### Serialization rules

**Serialize to AI (machine facts → bounded text):**

- language · question kind · spread semantic id + position roles  
- cards (canonical id, ritual id optional internal, orientation, position key)  
- supported relationships (kind + endpoints) when present  
- recurring card/theme claims **only** when evidence lists them  
- memory text within `RequestBounds.maxMemoryChars`  
- uncertainty / safety rules  

**Do NOT serialize:**

- Raw owner ids / storage keys / source adapter internals  
- Evidence provenance dumps / private question beyond sanitized ask  
- Unsupported relationship speculation  
- Signature shadow fingerprints as user copy  

AI must **not** reinvent role · structure · relationship kind · recurrence · memory inclusion · owner identity.

---

## 3 — Phase 3 generalization design (LOCKED CONCEPT)

Smallest seam — **no scorer/selector duplication · no mutable global edge injection · no Crossroads-as-fiveCard**:

```
SpreadSemanticResolver
  resolve(TarotSpreadType | SignatureSpreadId) → SpreadSemanticDefinition

PositionEdgeProvider
  edgesFor(SpreadSemanticDefinition) → List<AuthoritativePositionEdge>
```

| Provider | Behavior | 6A status |
|---|---|---|
| `ClassicalSpreadSemanticResolver` | Exact current `ClassicalSpreadSemantics.byLegacyTypeName` | **IMPLEMENTED** · parity PASS |
| `ClassicalPositionEdgeProvider` | Exact current `kAuthoritativePositionEdges` filter | **IMPLEMENTED** · parity PASS |
| `SignatureNarrativeSpreadResolver` | Phase 5 projection definitions (Crossroads only) | **IMPLEMENTED** · no live callers |
| `SignatureNarrativeEdgeProvider` | Phase 5 Signature edges (Crossroads 4) | **IMPLEMENTED** · no live callers |

`NarrativeEvidenceValidation.resolveSpread` and relationship pairing/scorer/selector are **resolver/provider consumers** with Classical defaults. Default `NarrativeEvidenceBuilder.build` unchanged — Crossroads still fails closed. Classical frozen corpus parity required byte-for-byte.

**Phase 6A (2026-09-23):** seam A/B infrastructure **PASS**. Seam C and 6G (full Crossroads Narrative) **NOT** implemented.

**Phase 6A.1 (2026-09-23) — LOCKED fail-closed rule:**

- Resolver/provider pair mismatch **must fail closed**.
- **A Signature semantic definition may never be evaluated with the Classical edge provider.**
- **A Classical semantic definition may never be evaluated with the Signature edge provider.**
- Valid `classical.single` zero-edge remains allowed only after Classical identity is proven.

---

## 4 — Phase 4 Signature history design (LOCKED CONCEPT)

```
SignatureHistoryNormalizer
  tryNormalize(persistedSpread / session) → SpreadSemanticDefinition?
```

- Classical path unchanged via existing `classicalFromSpread`  
- Crossroads → `signature.crossroads` definition **without** mapping to fiveCard  
- Preserve: owner isolation · source existence · H7 · H19 · delete/clear · privacyBlocked · `forbidSameSpreadAloneAuth=true`  

Classical-only assumptions to reopen only in explicit slices: `classicalFromSpread` null for Crossroads; session normalize skip.

---

## 5 — Result contract architecture (LOCKED)

### Choice: **Keep `InterpretationResult` as transport/UI bridge; add `NarrativeInterpretationValidation` before format**

| Option | Verdict |
|---|---|
| Replace InterpretationResult immediately | Rejected — UI/journal/OR blast radius |
| New Narrative result only (no bridge) | Rejected for classical cutover |
| **Narrative-validated InterpretationResult (+ later section policy)** | **Accepted** |

Near-term:

1. Provider returns structured or markdown sections  
2. Parse → `InterpretationResult`  
3. **Narrative quality validator** (card/spread/relationship/memory gates)  
4. Existing `AiOutputQualityTarot` still runs (must not reduce)  
5. `InterpretationFormatter.toUiContent` unchanged initially  

Later slice may introduce question-kind / spread-aware **optional** sections without forcing love/career/money for every kind — UI migration then.

---

## 6 — Structured provider output (LOCKED)

**Required: YES** for Narrative cutover (prefer explicit schema over free-form markdown).

Minimum schema concepts:

- `summary` (required)  
- `sections[]` with allowed kinds + max count + prose bounds  
- optional life-area sections only when question/spread policy allows  
- `closingMessage`  
- locale  
- **no** raw evidence ids in prose  

If backend cannot enforce JSON schema yet: client strict parse + reject partial → fail-closed (no charge). Backend migration tracked as required for production cutover.

**BACKEND CONTRACT CHANGE REQUIRED: YES** (payload + preferably response schema).

**CACHE VERSIONING REQUIRED: YES** (`narrativeTarotVersion` + evidence fingerprint + locale + spread id).

---

## 7 — Dual-run / shadow strategy (LOCKED)

1. **Deterministic harness first** — classical shadow Narrative request vs legacy ReadingContext facts (no provider cost).  
2. **Offline corpus** — fixture Narrative requests → serializer snapshots.  
3. **Provider shadow** — only in controlled non-user builds / capped QA; never double-charge; never dual-call on paid user path by default.  
4. Live cutover only after classical structural gates + quality corpus pass.

---

## 8 — Safety path (LOCKED)

- SensitiveTopicGate remains **before** Narrative build  
- Safety copy bypasses Narrative V2  
- Do not weaken detector  

### Delivery kind contract (LOCKED — Phase 6.0.1 / 6.0.2)

`AiReadingContent.deliveryKind` / `TarotReadingDeliveryKind`:

| Kind | Meaning | Bill | Journal / memory |
|---|---|---|---|
| `interpretation` | Normal AI / local interpretation | YES (after usable + commit) | YES |
| `safety` | SensitiveTopicGate **pure** safety copy | **NO** | **NO** |
| `recovery` | Already-charged recovery fallback | **NO second charge** | YES |

**YES — safety-only response is non-billable and non-journal.**

#### Safety output (LOCKED — Phase 6.0.2)

Safety is **pure safety content, not a Tarot interpretation**.

- Built by dedicated `TarotInterpretationService.safetyResponse` — **not** `emergencyFallback`
- `generalMeaning` / `fullInterpretation` = exact localized `SensitiveTopicGate` reason
- No card-derived prose · empty life-area / lucky / cardReadings · `drawnCards = []`
- UI: safety panel only — no story strip / cards / relations / detail layers / insight copy
- No journey-complete cue · no reveal ceremony

#### Recovery (LOCKED — Phase 6.0.2)

Recovery is **valid only for an already-settled session** (`alreadyCharged(session.id)`).

Uncharged `deliveryKind: recovery` → fail closed (`null`) — never charge, never convert to interpretation.

#### Delivery kind survival (LOCKED — Phase 6.0.2)

`deliveryKind` **must survive all content reconstruction** (e.g. `tarotContentWithSummary`).

#### Safety ordering (LOCKED — Phase 6.0.3)

```text
empty/impossible session guard
→ safety preflight (SensitiveTopicGate → safetyResponse)
→ affordability
→ paid interpretation load
→ usability
→ commit gate
```

Safety must **not** require gem balance. Preflight runs before `canAfford` and does **not** invoke `load`.

#### Safety quality / reinterpret (LOCKED — Phase 6.0.3)

- Quality/retry actions: **DISABLED** for safety  
- Safety content: **never versioned**  
- Safety session interpretation: **never written** (including reinterpret path)

Completion gate: after `_usable` + `shouldCommit`, inspect `deliveryKind` — `safety` free; `recovery` only if settled; else `markProviderOk` → `commit`. Controller must not persist safety prose into `ReadingSession.interpretation`. ReadingScreen must not auto-journal or expose Save / Reflection / Ask Oracle / Share / Favorite for safety.

---

## 9 — AI Quality V2 acceptance (testable)

Must pass existing `AiOutputQualityTarot` **plus**:

- Every drawn card grounded in prose or structured refs  
- Positions respected  
- Relationships used only when evidence supports; never invent unsupported kinds  
- Recurrence / memory claims only from included evidence  
- No contradictory history  
- No deterministic prophecy  
- Question answered · locale correct · bounded verbosity  
- No private evidence/source ids  
- No canned local success in release  
- Failures remain honest (null / typed error / no fake success)

---

## 10 — Phase 6 implementation sequence

### 6A — Spread semantic + edge provider seams (Phase 3 reopen: narrow)

- **Status:** **PASS** (2026-09-23) — Classical-preserving seams landed  
- **Goal:** Classical resolver/provider parity; Signature provider plumbing without live calls  
- **Reopen:** evidence validation resolveSpread + pairing/scorer/selector edge provider only  
- **Added:** `narrative_spread_semantic_resolver.dart` · `narrative_position_edge_provider.dart` · Signature adapters  
- **Tests:** classical parity · Signature Crossroads edges · provider propagation · Crossroads builder firewall  
- **Live impact:** NONE · Crossroads picker false · default builder Crossroads still unsupported  
- **Not done:** seam C · 6G full Crossroads Narrative · builder Signature wiring  
- **Rollback:** restore classical-only resolve (defaults already Classical)  
- **Next:** **Phase 6A.1** (provider identity fail-closed)

### 6A.1 — Provider/spread identity fail-closed hardening

- **Status:** **PASS** (2026-09-23) — pending independent ChatGPT verification  
- **Goal:** Classical/Signature edge providers reject mismatched spreads (no silent empty)  
- **Production:** `ClassicalPositionEdgeProvider` · `SignatureNarrativeEdgeProvider` only  
- **Rule:** Signature definition ↔ Classical provider and Classical definition ↔ Signature provider **must throw**  
- **Live impact:** NONE  
- **Next:** Independent verify → **Phase 6B**

### 6B — Signature history normalizer (Phase 4 reopen: narrow)

- **Status:** **PASS** (2026-09-24) — functional behavior independently verified; follow-up → 6B.1  
- **Goal:** Crossroads history normalize as `signature.crossroads`  
- **Added:** `SignatureHistorySpreadNormalizer` · `supportedFromSpread` / `supportedFromPersisted`  
- **Preserve:** H7/H19/privacy/owner/source/forbidSameSpreadAlone · `classicalFromSpread` Classical-only  
- **Live impact:** NONE (still no live V2 · picker false · current Crossroads builder unsupported)  
- **Rollback:** session/legacy resolve via `classicalFromSpread` / `classicalFromTitle` only  
- **Next:** **Phase 6B.1**

### 6B.1 — Signature history resolver unexpected-error hardening

- **Status:** **PASS** (2026-09-24) — independently verified  
- **Goal:** Remove broad catch that silently converted Crossroads resolver invariant failures into `skippedMalformed`  
- **Production:** `signature_history_spread_normalizer.dart` only  
- **LOCKED:** Malformed persisted spread data may fail closed. Internal Signature semantic-resolution invariant failures must not be silently converted into malformed-history skips.  
- **Next:** **Phase 6C**

### 6C — Narrative request → model-input serializer + cache identity

- **Status:** **PASS** (2026-09-24) — independently verified; follow-up → **6C.1**  
- **Goal:** Pure `TarotNarrativeRequest` → `NarrativeTarotPromptInput`; canonical form; SHA-256 V2 cache identity  
- **Package:** `lib/features/tarot/narrative/prompt/`  
- **Serializer version:** `1` · **Policy:** `narrative_policy_v1`  
- **Live call sites:** **0** (dormant)  
- **Unchanged:** backend · `OraclyAiService` · `AiInterpretationExecutor` · `ReadingContext.cacheKey` · live proxy payload  
- **OPEN MINOR (resolved in 6D):** exact external backend JSON field names  
- **Live Narrative V2:** still **NOT WIRED**  
- **Next:** **Phase 6C.1**

### 6C.1 — Narrative prompt structural integrity + version/locale fail-closed

- **Status:** **PASS** (2026-09-24) — independently verified; follow-up → **6C.2**  
- **LOCKED:**  
  - `interpretationOrder` exact permutation of position indices  
  - relationship card ↔ position correspondence; no self-pairs  
  - current Narrative / serializer / policy versions validated (cache namespace cannot lie)  
  - normalized supported locales only: `tr` / `en` / `ru`  
  - v1 relationship `noteKeyOrText` **NOT** model-facing  
  - excluded memory (`included=false`) cannot carry hidden entries  
- **Serializer version remains 1** (pre-freeze hardening, not a schema bump)  
- **Live call sites:** **0**  
- **Next:** **Phase 6C.2**

### 6C.2 — Canonical bounds + model-facing scalar integrity + locale-consistent Signature fixture

- **Status:** **PASS** (2026-09-24) — independently verified · Phase 6C **FROZEN**  
- **LOCKED:**  
  - request bounds may only tighten canonical `RequestBounds.defaults`  
  - relationship strength finite `[0,1]`  
  - theme relevance finite `[0,1]` · supportCount `≥ 2`  
  - memory confidence finite `[0,1]` · empty included content rejected  
  - recurrence/support/prior counts coherent and non-negative  
  - accepted model numbers finite (no NaN/±Infinity)  
  - TEST-ONLY Signature requests must be locale-consistent  
  - production locale authority remains Narrative Evidence Builder / authored deck data  
- **Serializer / policy version:** still **1** / `narrative_policy_v1`  
- **Live call sites:** **0**  
- **Next:** **Phase 6D**

### 6D — Structured result parse + Narrative quality validator

- **Status:** **PASS** (2026-09-24) — independently verified; follow-up → **6D.1**  
- **Request exact fields:** `mode` · `contractVersion` · `language` · `narrative` (`mode=narrative_v2`, `contractVersion=1`)  
- **Narrative object:** Phase 6C canonical field names reused  
- **Result contract version:** **1**  
- **Result exact top-level fields:** `contractVersion` · `languageCode` · `summary` · `cardReadings` · `synthesis` · `relationshipInsights` · `recurringCardInsights` · `recurringThemeInsights` · `memoryInsights` · `lifeAreas` · `advice` · `reflectionPrompt` · `dailyFocus` · `closingMessage`  
- **Provider:** strict `json_schema` name `oracly_tarot_narrative_v1` · no free-form Narrative markdown  
- **Flutter packages:** `narrative/transport/` · `narrative/result/` (dormant; live call sites **0**)  
- **Backend modules:** `narrative-tarot-contract|prompts|result-schema|result` + narrow `validate-request` / `service` branch  
- **Legacy path:** unchanged `{ text }`  
- **Exact backend JSON field-name minor:** **RESOLVED**  
- **Independent follow-up:** M1 shallow inbound validation · M2 weak Narrative fingerprint → **6D.1**  
- **Open minor remaining:** life-area UI migration timing only  
- **Next:** **Phase 6D.1**

### 6D.1 — Narrative backend input firewall + full semantic request fingerprint

- **Status:** **PASS** (2026-09-24) — independently verified · **FROZEN** with 6D  
- **LOCKED:**  
  - backend is independent untrusted-client validation boundary  
  - complete V1 enum/value contract (spread/question/geometry/role/temporal/relationship/transform/memory)  
  - max Narrative JSON **32,000** chars · no silent truncation/sanitization  
  - Narrative duplicate identity = SHA-256 of canonical full validated wire semantics (`tarot-narrative:<hex>`)  
  - raw private/user prose never appears in fingerprint string  
  - current `spread.spreadId` strict V1 machine ids; historical occurrence ids allow Phase 4 legacy aliases  
- **Flutter production:** **unchanged**  
- **Next:** **Phase 6E**

### 6E — Classical dual-run harness + shadow corpus

- **Status:** **PASS** (2026-09-24) — independently verified; follow-up → **6E.1**  
- **Deterministic / offline portion:** Classical dual-run harness · 24/24 launch structural parity · 22/22 seven/celtic non-launch · offline result assessor · provider shadow manifest  
- **Live impact:** NONE · no double charge · real provider calls **0**  
- **Prose parity:** **NOT required** (shared reading facts only)  
- **Orchestration:** Phase 5 Classical components by reference; live Classical migration question semantics are **not** restricted by Signature Quick Insight marketing gate  
- **Independent follow-up:** M1 broad exception swallowing · M2 shallow wire immutability · M3 parity ritual early-exit → **6E.1**  
- **LOCKED:** 6F live cutover requires:  
  1. 6E deterministic 24/24 structural parity  
  2. 6E offline result pipeline PASS  
  3. separate explicitly authorized controlled real-provider shadow evaluation (manifest max 6)  
  4. independent review of those provider outputs  
- **Real provider quality claimed by 6E alone:** **NO**  
- **Next:** **Phase 6E.1**

### 6E.1 — Shadow harness fail-loud + deep immutability + parity report accuracy

- **Status:** **IMPLEMENTED** (2026-09-24) — pending independent ChatGPT verification  
- **LOCKED:**  
  - shadow harness unexpected invariant/programming errors fail loud  
  - expected frozen-contract failures may map to `serializationFailed` only via known `ArgumentError`  
  - shadow wire snapshot deep immutable  
  - every parity dimension evaluated independently (no early-exit)  
  - live Classical migration question semantics are not restricted by Signature product marketing gate  
- **Production scope:** `narrative/shadow/**` only  
- **Next:** Independent verify → **controlled real-provider Narrative shadow QA (max 6 authorized calls) — NOT 6F yet**

### 6F — Classical live cutover (single/three/five only)

- **Goal:** Wired classical Narrative path under fail-closed + billing boundary  
- **Crossroads picker:** still false  
- **Rollback:** flag/code path back to legacy payload builder  

### 6G — Crossroads internal Narrative support (still picker false)

- **Goal:** Evidence + history + serializer for Crossroads internally  
- **Picker:** false  

### 6H — Phase 6 final audit

- **Goal:** Independent freeze candidate for classical Narrative live; Crossroads still gated by 7/8  

No slice combines scorer rewrite + history + live cutover + picker.

---

## 11 — Reopening rule

Phase 3/4 edits **only** inside documented slices 6A/6B with:

- exact files · invariant · parity tests · rollback  

Phase 5 catalog/product decisions remain frozen; Signature edges stay Phase-5-owned until provider seam consumes them **by reference**.

---

## 12 — Red-team contracts (count = **28**)

1. Classical spread semantic drift  
2. Crossroads fake fiveCard fallback  
3. Missing Signature edges  
4. Duplicate scorer implementation  
5. Memory hallucination  
6. Recurrence without evidence  
7. H7 regression  
8. H19 nondeterminism  
9. Owner/source leakage  
10. Private text leakage  
11. Prompt oversize  
12. Stale cache after V2  
13. Locale drift  
14. Unsupported relationship Crossroads  
15. Malformed structured result accepted  
16. Partial structured result as success  
17. Quality retry bypass  
18. Local fallback in release  
19. Provider failure charged  
20. Double charge  
21. Cached failure as success  
22. Safety path charged improperly  
23. Result UI crash on schema change  
24. History save before valid result  
25. OR context losing spread semantics  
26. Raw evidence ids in prose  
27. Crossroads picker premature  
28. PromptEngine / proxy payload divergence (legacy adapter lies)

---

## 13 — Open decisions

### OPEN BLOCKER DESIGN DECISIONS

**0**

### OPEN MAJOR DESIGN DECISIONS

**0** — Prompt strategy C, result bridge, resolver/provider seams, dual-run order, structured output required, cache versioning required are locked above.

### OPEN MINOR DESIGN DECISIONS

1. How soon UI drops forced love/career/money for non-life-area question kinds (after classical cutover).  

~~Exact JSON schema field names~~ → **RESOLVED** in Phase 6D (request + result field names locked above).  

~~Safety-only non-billable via content flag~~ → **LOCKED YES** in Phase 6.0.1 (`TarotReadingDeliveryKind.safety`).  

---

## 14 — Explicit non-claims

- 6.0 does **not** wire live Narrative V2  
- 6.0 does **not** enable Crossroads picker  
- 6.0 does **not** modify production/tests/fixtures  
- Phase 6 ≠ App Store / visual / ritual E2E readiness  

---

## 15 — Next

**Independent Phase 6E.1 verification**, then **controlled real-provider Narrative shadow QA — maximum six authorized calls — NOT 6F yet.**

Phase 6A–6E independently verified · Phase 6C/6D **FROZEN**. Phase 6E.1 harness hardening **IMPLEMENTED** (pending verify). Real provider quality **NOT** evaluated. Live Narrative V2 still **NOT WIRED**.
