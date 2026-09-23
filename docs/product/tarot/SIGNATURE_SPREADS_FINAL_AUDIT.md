# Signature Spreads — Phase 5F Independent Final Audit

**Phase:** 5F · **Kind:** AUDIT-ONLY · **Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Worktree:** `D:/oracly_final_r1`  
**START HEAD:** `7e2e6e963caee375e59e1ff956c937d2d18383d8`  
**END HEAD:** freeze docs commit on this branch (see Phase 5F report / `git rev-parse HEAD` after push)

**Verdict:** **PASS** · **Phase 5 FROZEN:** **YES**

Crossroads remains **shadow-only / picker-disabled**. This freeze does **not** mean live Narrative V2, AI migration, visual system, ritual E2E, or App Store readiness.

---

## 1 — Baseline & methodology

### Expected program state (contract)

| Layer | State |
|---|---|
| Phase 3 Narrative Evidence | FROZEN |
| Phase 4 Memory / History | FROZEN |
| Phase 5.0 → 5E | Complete on START HEAD |

### Crossroads expected capability (deliberate NOs are not defects)

| Capability | Expected |
|---|---|
| Runtime / persistence / l10n / structural projection / Phase 5 edges | YES |
| Phase 3 builder / Signature-edge scoring / Phase 4 history / live V2 / picker | NO |

### Independence rule

Conclusions below are from **production source**, **literal fixtures**, and **fresh test execution**.  
CURRENT_HANDOFF / PROMPT_LEDGER / prior reports were treated as claims only.

### Methods used

1. `git rev-parse` / `git diff 61134c81..HEAD` production scope  
2. Direct reads of `signature_spreads/`, persistence, pickers, l10n tables  
3. Independent Python recompute of shadow corpus metadata  
4. Import/importer scans for ShadowEvaluator + edge table contamination  
5. Fresh Flutter suites + `flutter analyze` + FULL suite  

---

## 2 — Changed-file / scope audit

### Phase 5 base

`61134c811f9073d466cbc423a17692abaab76612` → HEAD ancestor: **YES**

### Production `lib/` changes in Phase 5 window

Primary additions under `lib/features/tarot/signature_spreads/` (5A–5E).  
Supporting dual-read / display / picker firewall / l10n tables / reading model `positionKey` / `ReadingService` machine-id write / OracleReadingContext display fix.

### Frozen Phase 3 / 4 production

```
git diff --name-only 61134c81..HEAD -- lib/features/tarot/narrative/evidence/
git diff --name-only 61134c81..HEAD -- lib/features/tarot/narrative/history/
```

**Result:** **empty** — Phase 3 evidence + Phase 4 history production **intact / unmodified** in the Phase 5 window.

### Other fire walls

| Check | Result |
|---|---|
| Backend / billing production | No Phase 5 changes observed in scope audit |
| `release/ios-1.0` | `1b7151dca954f0cc25f39f815c0dacf0613a1164` (Build 4) |
| Merge into release | NO |
| Live Narrative V2 wiring | NOT present |
| Accidental Crossroads picker exposure | NO |

**PHASE 5 CHANGED-FILE SCOPE: PASS**

---

## 3 — Launch catalog & Crossroads structure

| Check | Result |
|---|---|
| Count | **4** |
| Order | `classical.single` → `classical.threeCard` → `classical.fiveCard` → `signature.crossroads` |
| Public launch list | `List.unmodifiable` |
| Unique IDs / runtime names | YES |
| Hidden 5th launch spread | NO |

### Crossroads positions (source)

| Index | Key | Role |
|---|---|---|
| 0 | `option_a` | direction |
| 1 | `option_b` | direction |
| 2 | `tension` | challenge |
| 3 | `counsel` | support |
| 4 | `direction` | direction |

Supported kinds: **decision · open · guidance** · Relationship: **unsupported** · Picker: **false**

### Crossroads edges (Phase-5-owned)

1. `option_a` ↔ `option_b` · opposition · undirected  
2. `tension` ↔ `option_a` · pressure · undirected  
3. `tension` ↔ `option_b` · pressure · undirected  
4. `counsel` → `direction` · supportive · directed  

Projected relation rows: **7** (3×2 + 1).  
`kAuthoritativePositionEdges`: **no Crossroads / option_a contamination** (grep empty).

**CROSSROADS EDGE EXACTNESS: PASS**

---

## 4 — Classical projection parity

Projector for `classical.*` returns frozen `ClassicalSpreadSemantics.bySpreadId(...)` as `projected` — identity reuse, not a second catalog.

Shadow classical path calls frozen `NarrativeEvidenceBuilder.build` for single / threeCard / fiveCard.  
Parity tests (5E) compare spread id, language, question kind, card/position order, relationship evidence ids, bounds.

**CLASSICAL SEMANTIC DRIFT: NO**

---

## 5 — Runtime enum & pickers

Enum order (source):

0 `single` · 1 `threeCard` · 2 `fiveCard` · 3 `sevenCard` · 4 `celticCross` · 5 `crossroads`

Existing 0–4 indices preserved. Crossroads `cardCount=5`.

| Surface | Crossroads offered |
|---|---|
| `TarotEntrySpreadChoice.offered()` | NO |
| `TarotRitualSpreadScreen.offeredSpreads` | NO |
| `TarotTableSpreadOverlay.options` | NO |
| `TarotSpreadType.values` in production pickers | Not used for picker lists |

**CROSSROADS USER REACHABLE: NO**

---

## 6 — Persistence / recovery / positionKey

| Contract | Source verdict |
|---|---|
| New write `session.spread.name` | `ReadingService` L93 **PASS** |
| Dual-read machine + TR/EN/RU + aliases | `fromPersisted` / `fromTitle` **PASS** |
| Unknown → null (never fabricate `single`) | Session codec + recovery **PASS** |
| `positionKey` optional persist | Snapshot + save path **PASS** |
| Reconstruct via spread + index | `TarotPositionKeyCompat` **PASS** |

---

## 7 — Machine-id UI / search

Audited production paths use localized resolvers for known machine ids:

| Surface | Verdict |
|---|---|
| Continue Reading | `TarotL10n.spreadFromStorage` |
| SavedReadingParser tagline/theme | `displayType = readingType ?? spreadLabel` |
| History `typeLabel` | `spreadFromStorage` |
| PersonalJourney / Mapper / Catalogue search | raw **OR** `typeLabel` |
| OracleReadingContext multi-card title | `TarotHistoryPrivacy.spreadTitle` |

**Residual INFO:** unknown garbage strings still fall through to raw in `spreadFromStorage` / `spreadTitle`. Known enum machine ids do not leak.

**RAW MACHINE-ID USER LEAKS (known ids): NONE MATERIAL**  
**LOCALIZED HISTORY SEARCH: PASS**

---

## 8 — Localization & copy

TR/EN/RU titles verified for threeCard / fiveCard / crossroads.  
Crossroads purpose copy is reflective (options + tension + honest next step) — no certainty/prophecy.

Legacy blurb alias parity covered by Phase 5C tests (still green).

**COPY SAFETY: PASS**

---

## 9 — Phase 3 / 4 fire walls

| Check | Result |
|---|---|
| `ClassicalSpreadSemantics.byLegacyTypeName('crossroads')` | throws unknown classical |
| Crossroads `NarrativeEvidenceBuilder` | fails closed · **no fiveCard fallback** |
| Crossroads session normalize | `record=null` · `skippedMalformed` |
| Crossroads legacy ReadingModel normalize | `record=null` · `skippedMalformed` |
| H7 / H19 production in Phase 5 window | **unchanged** (history package diff empty) |

---

## 10 — Shadow evaluator

| Property | Verdict |
|---|---|
| IO / network / persistence / AI / analytics / billing / UI | **0** |
| `DateTime.now` / `Random` / `hashCode` fingerprint | **0** |
| Explicit `now` required when history supplied | YES |
| sevenCard / celticCross | typed `unsupportedRuntimeSpread` |
| Crossroads | structural-only · no Phase3/4 requests |
| User-path importers of ShadowEvaluator outside package | **0** |
| Production call sites | **0** |

### Broad `catch (_)` (S)

`SignatureSpreadShadowClassical.buildEvidence` swallows all exceptions → `null` → `evidenceBuildFailed`.

**Severity: MINOR** (contract debt).  
Risk: unexpected programming errors could be normalized as typed input failure.  
Not BLOCKER/MAJOR for freeze: classical parity proves happy path; Crossroads never enters this catch; no demonstrated corruption of reachable 1/3/5.

Preferred future remediation: catch only known `NarrativeEvidenceException` (or equivalent), rethrow unexpected.

### Firewall test exemption (T)

Phase 3 importer scans exclude `signature_spreads`.  
Independent scan: **no** ShadowEvaluator / scorer / selector imports outside Signature package into UI/runtime/services.

**FIREWALL TEST EXEMPTION AUDIT: PASS** (exemption bounded; no blind live path)

---

## 11 — Shadow corpus (independent)

Fixture: `test/fixtures/tarot_signature_shadow_v1.json`

| Metric | Value |
|---|---|
| Header `scenarioCount` | 16 |
| Actual scenarios | **16** (match) |
| Scenario IDs unique | YES |
| Languages | TR · EN · RU |
| OK / reject | 13 / 3 |
| Rejects | QI decision · QI relationship · CR relationship |
| Distinctness pair | `df_open_en` ↔ `cr_decision_en` (`same_five_v1`) |
| Dump helper auto-run | NO (`skip: 'dump only…'`) |

Coverage classes present in fixture: QI open/guidance + rejects; Timeline open/relationship/decision; Deep Field open/guidance/relationship/decision; Crossroads decision/guidance/open + relationship reject; mixed reversals.

**CORPUS DETERMINISM: PASS** (corpus lock test green)

---

## 12 — Migration seam & Phase 6 doc

`SignatureSpreadMigrationSeam` Crossroads: runtime/persistence/l10n/projection **true**; phase3/phase4/live V2/picker **false**; Signature edges **not consumed**.

`SIGNATURE_SPREADS_PHASE6_SEAM_AUDIT.md`: seams A–L present.

| Class | Count |
|---|---|
| Phase 6 BLOCKER (before live Crossroads) | **8** (A–E, I–K) |
| Phase 6 MAJOR (before live V2) | **4** (F–H, L) |

Independent review: classifications remain accurate — **no count change**.

---

## 13 — Security / privacy

Shadow results / fixture use synthetic ids/questions.  
No owner email/token/API key/connected-memory bodies in Phase 5 fixtures.  
Exception path for evidence build does not embed user question into Shadow failure codes.

---

## 14 — Skipped-test audit

FULL suite: **4184 passed · 16 skipped · 0 failed**

| Category | Examples | Phase 5 relevant blocker? |
|---|---|---|
| Conditional AI E2E (`ORACLY_E2E!=1`) | `ai_local_e2e_*`, `ai_user_flow_*`, companion live chat | NO |
| Phase 5 dump helper | `signature_shadow_corpus_dump_test` | NO (intentional dump-only; corpus lock test runs) |

**PHASE5 RELEVANT SKIPPED BLOCKER TESTS: 0**

---

## 15 — Regression matrix (fresh)

| Suite | Result |
|---|---|
| Phase 5A–5E / projection / shadow corpus | PASS |
| Phase3 / Phase4 Crossroads firewalls | PASS |
| Narrative Evidence / Domain / History / V2 | PASS |
| Privacy / R2 / localization | PASS |
| Spread engine / entry / ritual / history / search / saved reading | PASS |
| `flutter analyze` | **199 info · 0 error · 0 warning** |
| FULL Flutter | **4184 · ~16 · 0 fail** |

---

## 16 — Severity table

| ID | Severity | Finding |
|---|---|---|
| — | BLOCKER | **0** |
| — | MAJOR | **0** |
| M1 | MINOR | Broad `catch (_)` in classical shadow evidence build |
| I1 | INFO | Unknown persisted strings still fall through to raw display helpers |
| I2 | INFO | Classical journal short titles in `TarotHistoryPrivacy` remain hard-coded TR (pre-existing) |
| I3 | INFO | Analyze infos (199) pre-existing / non-failing |

---

## 17 — Freeze decision

**BLOCKER = 0 · MAJOR = 0 · core contracts PASS**

### PHASE 5 — SIGNATURE SPREADS **FROZEN**

### Explicit non-claims

- Crossroads is **not** live  
- Narrative V2 is **not** wired  
- AI Narrative result pipeline is **not** complete  
- Visual / ritual E2E / release readiness are **out of scope** for this freeze  

### Next canonical phase

**Phase 6 — AI Narrative result pipeline + migration**  
(must implement Phase 6 seam audit A–L before Crossroads live Narrative)

---

## 18 — 5F artifact list

| Artifact | Action |
|---|---|
| This document | CREATED |
| `CURRENT_HANDOFF.md` | UPDATED (freeze record) |
| `PROMPT_LEDGER.md` | UPDATED (PL-T5F) |
| Production / tests / fixtures | **NONE** (audit-only) |
