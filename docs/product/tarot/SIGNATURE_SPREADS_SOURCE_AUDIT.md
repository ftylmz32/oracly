# Signature Spreads — Source Audit (Phase 5.0)

**Date:** 2026-09-23  
**Branch:** `fix/final-product-remediation-20260922`  
**Audit start SHA:** `61134c811f9073d466cbc423a17692abaab76612`  
**Posture:** Independent production forensic. Docs alone are not evidence.  
**Production files modified:** **NONE**

**Frozen context:** Phase 3 FROZEN · Phase 4 FROZEN (4E re-audit) · Live Narrative V2 **NOT WIRED** · `release/ios-1.0` Build 4 untouched.

---

## A — Current user-reachable Tarot flow

Live spine (confirmed in production):

```
OraclyFeatureNavigation / OraclyRoutes.tarot
  → TarotModuleNavigator → TarotHomeScreen (= TarotTableScene)
  → TarotTableIntentOverlay (intention chips)
  → TarotTableSpreadOverlay (spread tiles: 1 / 3 / 5)
  → TarotTableFlow.startSession → DeckSelectionStart.confirm
  → TarotReadingController.beginSession
  → TarotRitualController shuffle/draw on table
  → TarotTableReadingOverlay → deepen → ReadingScreen
  → TarotReadingCompletion → TarotInterpretationService
  → InterpretationEngine → AiInterpretationExecutor
  → OpenAiPaidRequests.tarotReading
  → ReadingService.saveFromSession → or_reading_history
```

| Step | File · symbol | Behavior | User-reachable |
|---|---|---|---|
| Entry | `oracly_feature_navigation.dart` · `startTarotFlow` / `openTarotHome` | Opens Tarot module home | **YES** |
| Daily ritual | `daily_ritual_tarot_bridge.dart` | Forces **single** | **YES** |
| First session | `tarot_table_scene_state.dart` · `TarotFirstReading.spread` | Bypasses picker → single | **YES** |
| Spread UI | `tarot_table_spread_overlay.dart` | Offers single / threeCard / fiveCard | **YES** |
| Intention UI | `tarot_table_intent_overlay.dart` | love / career / future / inner / custom | **YES** |
| Session create | `tarot_reading_controller.dart` · `beginSession` | Creates `ReadingSession` | **YES** |
| Draw | `tarot_ritual_controller.dart` · `commitDraw` | Assigns positionIndex/key via `SpreadService` | **YES** |
| Complete | `tarot_reading_completion.dart` | Charges + interprets | **YES** |
| Persist | `reading_service.dart` · `saveFromSession` | Writes `ReadingModel` | **YES** |
| Result UI | `reading_screen.dart` + AI reading widgets | Shows interpretation | **YES** |
| Epic031 / RitualSpreadScreen / TarotSelectScreen | epic031 / ritual screens | Alternate pickers | **NO** (unmounted) |

**Narrative V2 / Phase 3–4 engines are not on this path.**

---

## B — Spread inventory matrix

| Runtime id | Legacy / display | Cards | User-reachable | Persisted | Narrative classical | Geometry | Notes |
|---|---|---|---|---|---|---|---|
| `single` | Tek Kart / One Card / `classical.single` | 1 | **YES** | YES | YES | linear | Daily + first session |
| `threeCard` | Üç Kart / Three Cards / `classical.threeCard` | 3 | **YES** | YES | YES | linear | Table overlay |
| `fiveCard` | **Derin Açılım** / Deep Spread / `classical.fiveCard` | 5 | **YES** | YES | YES | linear | Not titled “Five Cards” |
| `sevenCard` | Yedi Kart / `classical.sevenCard` | 7 | **NO** | possible restore | YES | preview clamp | Domain ready; not offered |
| `celticCross` | Kelt Haçı / `classical.celticCross` | 10 | **NO** | filter/sample only | YES | home preview painter | Not on table overlay |
| `signature.*` | fixture only | — | **NO** | NO | **NO** runtime | — | Corpus fixture only |
| Oracle-engine specialty | `oracle_engine_type.dart` | varies | **NO** | parallel | NO | — | Not ritual product |

**Counts:** runtime enum **5** · user-reachable **3** · Narrative classical semantic **5**.

---

## C — Phase 3 spread semantic foundation (frozen)

Models: `SpreadSemanticDefinition` · `SpreadPositionSemantic` · `ClassicalSpreadSemantics`.

### Fields that affect deterministic evidence

| Field | Effect |
|---|---|
| `cardCount` | Validation vs drawn cards |
| `positions` (`positionKey`, `index`, `role`) | Slot identity · pairing · closed universe |
| `interpretationOrder` | Orders builder card/context output |
| `legacyTypeName` | Authoritative edge table lookup |
| `spreadId` | Request identity · history normalize |

### Decorative / metadata only (unread by scorer/builder)

`purposeKey` · `geometryHook` · `lengthBand` · `guidingQuestionKey` · `temporal` · `displayLabelKey` · `weight` · catalog `relationToOtherSlots` (scorer uses `kAuthoritativePositionEdges`)

### Explicit answers

1. Evidence-affecting: cardCount, positions, interpretationOrder, legacyTypeName, spreadId  
2. Decorative: purposeKey, geometryHook, lengthBand, guidingQuestionKey, temporal, displayLabelKey, weight  
3. `purposeKey` scoring? **NO**  
4. `guidingQuestionKey` scoring? **NO**  
5. `geometryHook` evidence? **NO**  
6. `lengthBand` evidence? **NO**  
7. `interpretationOrder` evidence output? **YES** (order)  
8. Roles influencing kind selection: **`challenge`**, **`avoid`** (with opposition)  
9. Edges influencing scoring: opposition / temporal / pressure / supportive / mirror (all bonuses)  
10. Phase 5 extend without reopening Phase 3? **YES** — additive catalog + edges only

---

## D — Phase 4 interaction (frozen)

| Question | Answer |
|---|---|
| Eligibility depends on spread? | Only non-empty `spreadId` structural check |
| Context overlap uses spread identity? | **NO** |
| Same spread alone → recurrence? | **NO** |
| Recurring samples keep historical positionKey? | **YES** when present |
| Position keys global? | **NO** — per-spread |
| Memory/theme depend on classical ids? | **NO** |
| New signature positionKeys safe? | **YES** if adapters resolve via that reading’s definition + index |

**Phase 5 must obey:** do not make same-spread alone authorize recurrence; preserve empty-positionKey sample skip; keep eligibility independent of current spread type.

---

## E — Persistence / migration forensic

| Store | Field | Wire format |
|---|---|---|
| `ReadingSession` | `spread` | enum **`.name`** (`"single"`, …) |
| `ReadingModel` | `spreadType` | **locale display title at save** (`session.spread.label`) |
| Journal metadata | — | **no spread field** |
| Narrative history record | `spreadId` | `classical.*` (adapter) |

### Compatibility answers

1. Persisted today: session = enum name; history = localized label  
2. Enum index corruption? **NO** — names, not indices  
3. Append new enum values safely? **YES** if names never renamed  
4. Old ids parsed by? `fromTitle` (name + TR/EN/RU labels + hard aliases)  
5. Migration required for signature spreads? **YES** for history machine-id stability (see SPEC)  
6. Old readings reopen? History detail uses **stored markdown** (no re-AI); spread display via `fromTitle` / raw string  
7. Never rename: existing `TarotSpreadType` **names**; existing `classical.*` spreadIds; existing position **keys** already in history samples

| Risk | Severity | Mitigation (Phase 5C) |
|---|---|---|
| History locale-at-save | MAJOR | Persist stable machine id; keep `fromTitle` read path |
| Session `byName` hard fail | MAJOR | Soft-parse unknown → fail-closed UI, never crash |
| PositionKey absent on journal cards | MAJOR | Always reconstruct from index + spread definition |
| L10n title rename | MAJOR | Never rename without aliases |

---

## F — Localization forensic

Source: `lib/core/l10n/tables/table_tarot_flow.dart` (+ blurbs in `table_tarot.dart`).

| Key family | TR/EN/RU | Notes |
|---|---|---|
| `tarot.spread.{single,threeCard,fiveCard,sevenCard,celticCross}` | YES | fiveCard = Derin Açılım / Deep Spread |
| `.banner` / `.compact` / `.blurb` | mostly YES | celtic blurb incomplete |
| `tarot.pos.*` | YES | position labels |

Hardcoded TR titles still appear in dead `TarotHomeSpreads` data — not live overlay.

---

## G — UI / visual forensic

| Surface | Counts | Geometry |
|---|---|---|
| `TarotTableSpreadOverlay` | **1 / 3 / 5** | row placement by slot count |
| Ritual choice preview | clamps to **≤5** | 7/10 preview truncated |
| `SpreadLayoutPreview` | single / three / five / celtic | home dead data |
| Table scene | linear `placeTargetFor` | **not** true Celtic geometry |

**1 / 3 / 5** render on live table. **7 / 10** domain-capable but no live picker + weak geometry.

---

## H — Interpretation paths

### CURRENT USER PATH

```
ReadingScreen / table deepen
  → TarotReadingCompletion
  → TarotInterpretationService.generateContent(ReadingSession)
  → InterpretationEngine (+ prompt adapter)
  → AiInterpretationExecutor → OraclyAiService.generateTarotReading
  → ReflectiveIntelligence.guard → AiOutputQualityTarot
  → InterpretationFormatter → AiReadingContent UI
  → ReadingService.saveFromSession
```

### NARRATIVE V2 SHADOW PATH

```
NarrativeEvidenceBuilder.build  (Phase 3 — tests)
  → TarotNarrativeRequestEnricher.enrich  (Phase 4 — tests/shadow)
  → ⛔ STOPS — 0 production call sites outside history package
```

### Future Phase 6 seam (not wired)

Insert into `TarotInterpretationService` / `InterpretationEngine` **before** AI:

`NarrativeEvidenceBuilder` → optional `TarotNarrativeRequestEnricher` → Narrative synthesizer → quality → UI adapter.

Keep gem charge / fail-closed / ModuleRoot contracts.

---

## I — Product implication for Phase 5

Current live product already differentiates **three card counts**, but product copy still collapses “spread = count” (especially fiveCard titled Deep Spread without a true Decision/Relationship product).

Phase 5 must lock **signature products** on top of (and aligned with) classical semantics — not invent a second parallel enum universe.

Deferred (not launch-blocking): shipping sevenCard / celticCross to live picker until geometry + preview clamp + persistence machine-id are ready.

---

## Red-team attack surface (contracts derived → SPEC §M)

Unsupported persisted title · unknown spread id · cardCount mismatch · duplicate positionIndex/Key · missing position · wrong interpretationOrder · invalid edge · questionKind vs spread support · current cards ≠ spread · missing l10n · journal reopen · history recurrence from old spread · version bump · same cards different spreads → different evidence structure · reversed / unknown orientation · 1-card edges · Celtic complexity · small-screen a11y.

---

## Open decisions after forensic

| Class | Count | Items |
|---|---|---|
| **BLOCKER** | **0** | All launch blockers resolved in SPEC locks |
| **MAJOR** | **0** | History machine-id migration sequenced in 5C (specified, not open) |
| **MINOR** | **2** | celtic blurb completeness · dead home hardcoded TR titles cleanup later |

---

## Audit artifacts

- This document  
- Spec: `SIGNATURE_SPREADS_SPEC.md`

---

## Phase 5.0.1 independent-review hardening note (appended)

**Date:** 2026-09-23  
**Start SHA:** `a590da5e39a9c84466237e3decc120f9197735f6`

Independent ChatGPT review of Phase 5.0 accepted the direction and required contract hardening **before 5A**. Forensic facts above are **not rewritten**. Spec updates only:

1. **Crossroads roles exact:** `option_a`/`option_b`/`direction` → `PositionRole.direction`; `tension` → `challenge`; `counsel` → `support`. No new Phase 3 roles.
2. **Crossroads edges exact (4):** A↔B opposition; tension↔A/B pressure; counsel→direction supportive. No extra 5B edges.
3. **QuestionKinds:** decision (primary) · open · guidance · **relationship unsupported**.
4. **Geometry separation:** Phase 5 `SignatureGeometryHook` (incl. `fiveDecision`) · frozen `NarrativeGeometryHook` unmodified · Crossroads projects to `linearRow` for Phase 3 evidence.
5. **Enum timing:** Phase **5A must not** modify `TarotSpreadType`; append `crossroads(5)` only in **5D** after TR/EN/RU keys exist.
6. **Sequence reorder:** 5A domain/catalog → 5B projection/edges → 5C l10n/geometry → 5D runtime/persistence → 5E shadow corpus → 5F audit.

Compatibility check vs frozen Phase 3: `PositionRole.direction|challenge|support` and `PositionEdgeKind.opposition|pressure|supportive` already exist and are consumed by the frozen kind resolver / scorer bonuses — no Phase 3 change required.
