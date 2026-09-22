# TAROT PHASE 0 — Forensic Baseline

**Mode:** READ ONLY — no implementation  
**Branch:** `fix/final-product-remediation-20260922`  
**HEAD at audit:** `173d75228248baf32ea0d4f04fe936665efff342`  
**Worktree:** `D:/oracly_final_r1`  
**Date:** 2026-09-22

This document maps **current** Tarot reality against the locked Narrative Tarot + Visual System contract. It does **not** implement either program.

---

## Executive summary

| Question | Answer |
|---|---|
| 78 classical cards present in structured deck? | **YES** (`OraclyTarotDeck.expectedCount = 78`, major 22 / minor 56) |
| Production ritual deck source? | `DeckService` → `TarotContentCatalogue` (bridged meanings via `OraclyTarotBridge`) |
| Production interpretation path? | `ReadingScreen` → `TarotReadingCompletion` → `TarotReadingController.resolveInterpretationContent` → `TarotInterpretationService` → `InterpretationEngine` → `AiInterpretationExecutor` (prod) / local only when `allowsLocalFallback` |
| Narrative machinery already in repo? | **YES (local path)** — `lib/features/tarot/reading/*` + `TarotReadingEngine` used by `ReflectiveIntelligence.synthesize` → `LocalInterpretationExecutor` |
| Narrative machinery on AI path? | **PARTIAL** — prompt adapter sends cards/positions/question/journey facts; full `ReadingStory` composition is **not** the AI result schema |
| Recurring cards | **PARTIAL** — recent card names + theme labels injected; no dedicated recurring-card UI / frequency chronology product |
| Signature Spreads (“The Mirror”, etc.) | **ABSENT** as product — classical 1/3/5/7/Celtic exist |
| Visual System vs locked golden set | **PARTIAL** — strong ritual chrome pieces exist; locked golden masters / Signature geometry / narrative hierarchy **MISSING** |
| R2 / R2.1 | Production fail-closed + retry quality re-check **in place** |

---

## A. Card system

### Canonical structured deck

| Item | Evidence |
|---|---|
| Files | `deck/oracly_tarot_*.dart`, `deck/catalog/oracly_tarot_{major_00_10,major_11_21,wands,cups,swords,pentacles}.dart` |
| Count | `OraclyTarotDeck.expectedCount = 78` · `expectedMajor = 22` · `expectedMinor = 56` |
| Suits | `OraclyTarotSuit`: none (major), wands, cups, swords, pentacles |
| Courts | ranks 11–14 = page/knight/queen/king (`OraclyTarotRanks`) |
| Localization | `L10nTriple` TR/EN/RU on names, keywords, meanings, relation notes |
| Upright / reversed keywords | `uprightKeywords` + `reversedKeywords` on every card |
| Meanings fields | symbolic, love, career, money, personal, challenge, guidance, futureDirection |
| Relations | `OraclyTarotRelations.relatedIds` + localized note |
| Asset fields | `visualAsset` + default `cardBackAsset` (`OraclyTarotAssets.cardBack` SVG) |

### Production ritual mapping

| Item | Evidence |
|---|---|
| Draw deck | `DeckService.createDeck` → `TarotContentCatalogue.all` |
| Bridge | `OraclyTarotBridge.byRitualId` maps 0–77 → Oracly catalogue ids; reverse uses `challengeMeaning`, upright `symbolicMeaning` |

### Semantic categories vs Narrative Tarot target

| Category | Status | Notes |
|---|---|---|
| core meaning | **PARTIAL** | `symbolicMeaning` (+ catalogue meanings) — not a dedicated “core” profile object |
| light | **ABSENT** | no dedicated light aspect field |
| shadow | **PARTIAL** | `challengeMeaning` / reversed path approximates shadow; not named shadow |
| tension | **ABSENT** | |
| desire | **ABSENT** | |
| fear | **ABSENT** | |
| relationship | **PARTIAL** | loveMeaning + relation ids/notes — not relationship-dynamic profile |
| decision | **ABSENT** | |
| action | **PARTIAL** | guidance / futureDirection — not action-direction profile |
| reversed transformation | **PARTIAL** | separate reversed keywords + challengeMeaning; not full transform model |
| pair relation | **PARTIAL** | relatedIds + note; runtime `reading_relations.dart` for local story |
| combination relation | **PARTIAL** | local `ReadingRelations.after`; not AI structured combo model |

---

## B. Spread system

### Definitions

| Spread | Cards | Positions (keys) | File |
|---|---|---|---|
| single | 1 | `sign` | `tarot_spread_catalog.dart` / `tarot_spread_positions.dart` |
| threeCard | 3 | past / present / future | |
| fiveCard | 5 | situation / hidden_influence / challenge / strength / direction | |
| sevenCard | 7 | question / current_energy / obstacle / hidden_factor / what_helps / what_to_avoid / direction | |
| celticCross | 10 | present … outcome (10 classical slots) | |

Engine: `SpreadEngine` + `SpreadService.positionAt` resolve definitions by `TarotSpreadType`.

### Does position / purpose reach AI?

| Signal | Reachability |
|---|---|
| Position labels | **YES** — `ReadingContext` cards carry `positionLabel`; AI payload includes per-card position (`AiInterpretationExecutor._cardsPayload`, prompt cards summary) |
| Spread label | **YES** — `spreadLabel` / `spreadType` into AI + prompt |
| Interpretation order | Defined on `TarotSpreadDefinition.interpretationOrder` — used structurally; AI receives ordered card list |
| Card order effect | **YES** for local narrative (`ReadingStory` walks in list order); AI receives ordered cards with positions |

### Signature / custom spreads

| Capability | Status |
|---|---|
| ORACLY Signature Spreads (e.g. The Mirror) | **ABSENT** as named product |
| Classical multi-spread catalog | **EXISTS** |
| Home visual styles per spread | **EXISTS** (`SpreadVisualStyle`, living card painters) — presentation, not Signature product semantics |

**Do not add spreads in Phase 0.**

---

## C. Question / intention

| Piece | Location | Notes |
|---|---|---|
| Model | `TarotIntention { text, topic? }` in `tarot_spread.dart` | |
| Session | `ReadingSession.intention` | |
| Context | `ReadingContext.userQuestion`, `readingTheme` | |
| Local narrative | `ReadingQuestion` / `ReadingAsk` / `ReadingStory.opening` | Strong grounding when text present |
| AI client | Prompt adapter `intention` + `questionKind`; executor sends `userQuestion` / `readingTheme` | |
| Journey | Optional memory / revisit / themes | Evidence-only hints |

### Question grounding verdict

**PARTIAL → approaching STRONG on local path; PARTIAL on AI path.**

Evidence: local story templates explicitly frame the asked question; AI receives question + theme + cards but result schema is still fixed Love/Career/Money-style sections rather than narrative-first arc.

---

## D. Interpretation pipeline

### Production call chain

```
ReadingScreen._loadReading
  → JourneyPersonalizationBuilder (+ memory + revisit)
  → TarotReadingCompletion.complete(load: resolveInterpretationContent)
  → TarotReadingController.resolveInterpretationContent
  → TarotInterpretationService.generateContent
       SensitiveTopicGate.emergencyFallback (safety — keep)
       → InterpretationEngine.interpret
            → AiInterpretationExecutor.execute  [production when configured / unconfigured fail-closed]
            → LocalInterpretationExecutor        [only if allowsLocalFallback wiring]
       → ReflectiveIntelligence.guard
       → AiOutputQualityTarot.passes
       → bounded forceRefresh retry
       → _fallbackOrFail (local only if allowLocalFallback; else InterpretationException)
  → charge settle only after usable content
  → ReadingPremiumBody / TarotErrorState
```

### Retry / quality / fail-closed (post R2 + R2.1)

| Layer | Behavior |
|---|---|
| `InterpretationRetryPolicy.maxAttempts` | **2** (engine-internal) |
| Quality first fail | one forceRefresh interpret (service) |
| Quality still fail | `_fallbackOrFail` |
| Exception path | `_retryOrFallback` → forceRefresh once → **R2.1 re-checks quality** → `_fallbackOrFail` |
| Production `allowLocalFallback` | **false** via `ai.allowsLocalFallback` from ModuleRoot |
| Unconfigured release | `tarotInterpretationExecutorFor` → `AiInterpretationExecutor` (not Local) |
| Dev unconfigured + allowsLocalFallback | Local executor permitted |
| Stream path | `generateStream` / executor stream → **not production-reachable** from current UI |

### Where R2 / R2.1 changed the flow

- **R2:** explicit `allowLocalFallback`; no silent local success; wiring matrix; fail → `InterpretationException` / error UI.  
- **R2.1:** retry success path must pass `AiOutputQualityTarot` again before UI content.

---

## E. Narrative capability (critical)

| Module | Implemented? | Production reachable? | Used by AI? | Used by local? | Classification |
|---|---|---|---|---|---|
| `TarotReadingEngine` | YES | via local synthesize only | NO (not AI schema) | YES | CURRENT for local / fallback |
| `ReadingStory` / `ReadingStoryWalk` | YES | local path | NO | YES | CURRENT local narrative |
| `reading_relations.dart` | YES | local | NO | YES | CURRENT local |
| `reading_card_beat` / `reading_slot_sense` / `reading_guidance` / `reading_hedge` / `reading_ask` / `reading_question` | YES | local | prompt uses ask kind | YES | CURRENT local; partial AI prompt |
| `reading_story_*` UI widgets | YES | Reading premium UI | N/A | displays content | CURRENT presentation |
| `oracly_tarot_relations` | YES data | via bridge/meanings | related ids not deeply reasoned in AI | local relations may use meanings | PARTIAL |
| Prompt `readingPipeline` fact string | YES | AI prompt facts | YES (instructional) | — | PARTIAL (claim vs engine depth) |

**Conclusion:** Do **not** rebuild local narrative from scratch without audit reuse. AI path still needs Narrative Engine product work — existing local story is a foundation, not the locked release Narrative Tarot.

---

## F. Memory / personalization

| Capability | Status | Evidence |
|---|---|---|
| `JourneyPersonalizationHints` | **EXISTS** | themes, recentCardNames, priorReadingCount, notes, openings, revisit, memorySummary |
| Builder from history | **EXISTS** | `JourneyPersonalizationBuilder.fromHistory` |
| OraclyMemory into Tarot | **EXISTS** | `ReadingScreen` `withMemory` (optional; failures ignored) |
| Recent card names → AI | **EXISTS** | executor + prompt journey facts |
| Recurring theme labels → AI | **EXISTS** | same |
| Dedicated recurring-card detection UI | **ABSENT** | |
| Card frequency counts / dated recurrence product | **PARTIAL** | history exists; no first-class recurring-card feature |
| Preserve question/context in history | **PARTIAL** | session / journal fields — verify per entry model in later phases |
| Relevant vs irrelevant past filter | **PARTIAL** | observational preface / echoes fingerprint — not full relevance engine |
| Fabricated recurrence | Policy forbids; builder uses real history only | |

**Recurring-card capability (overall): PARTIAL**

---

## G. Result data model

### `InterpretationResult` / formatter sections

summary · love · career · money · health · spiritualGuidance · advice · warnings · luckyEnergy · dailyFocus · closingMessage · source · rawText

### `AiReadingContent` (UI)

cardName · tagline · generalMeaning · love · career · money · spiritualGuidance · luckyEnergy · dailyAdvice · closingMessage · cardReadings · fullInterpretation · drawnCards · spreadLabel · readingTheme · userQuestion · interpretationSource · imageAsset · rarityColor

### Narrative Tarot disposition (no code change)

| Field / pattern | Disposition |
|---|---|
| narrative summary / arc | **KEEP** direction — needs first-class narrative fields later |
| love / career / money forced sections | **REPLACE LATER** when irrelevant; today often filled |
| health / warnings / luckyEnergy / dailyFocus | **SECONDARY** / **LEGACY** candidates |
| closingMessage | **KEEP** (session ending / EPIC-015) |
| cardReadings / drawnCards | **KEEP** as secondary detail layer |
| `AiReadingCatalogue` static canned samples | **LEGACY** — not production AI path |

---

## H. Visual system (audit vs locked target)

| Target item | Classification | Evidence / gap |
|---|---|---|
| Card illustration primary | **STRONG** | webp faces in `lib/assets/images/tarot/**` |
| Physical / premium object feel | **PARTIAL** | shells, chrome, living painters — inconsistent across generations |
| Consistent frame / chrome | **PARTIAL** | multiple stacks (epic031, ritual, widgets, presentation) |
| Signature card back | **PARTIAL** | SVG backs under `assets/tarot/card_back/`; also painterly backs |
| Depth / shadow / glow / particles | **PARTIAL** | present; risk of overload in places |
| Editorial typography | **PARTIAL** | ReadingTypography used in reading; not uniformly Tarot-wide |
| Ritual pacing | **PARTIAL** | motion tokens / reveal timelines exist |
| Premium fan | **PARTIAL** | epic031 fan + selection UIs |
| Flip / reveal | **PARTIAL** | `card_reveal/*` |
| Selected-card focus | **PARTIAL** | |
| Spread composition hierarchy | **PARTIAL** | style-specific layouts; not Signature geometry product |
| Narrative result hierarchy | **MISSING** | premium body still section-oriented |
| Recurring-card history visual | **MISSING** | |
| Major/Minor weight | **MISSING / WEAK** | |
| Anti casino / glow overload | **PARTIAL** | policy exists in brand docs; visual variance remains |
| Reduced motion | **PARTIAL** | `OraclyReducedMotion` used on reading; not full Tarot golden coverage |
| Responsive 320 / 390 | **PARTIAL** | some Tarot entry tests at 390; no locked golden set |

**Overall Visual System: PARTIAL**

---

## I. Asset inventory

| Asset class | Count / note |
|---|---|
| Runtime major faces (webp) | **22** under `lib/assets/images/tarot/major_arcana` |
| Runtime minor faces (webp) | **56** under `lib/assets/images/tarot/minor_arcana/**` |
| Duplicate PNG siblings | **22** major + **56** minor also present (duplicate set) |
| Thumbs | **79** under `lib/assets/images/tarot/thumbs` |
| Card backs | `assets/tarot/card_back/*.svg` (portrait / safe / thumbnail) |
| Alternate English webp tree | `OraclyTarotAssets` points at `assets/tarot/cards` (79 files) — parallel to shipped Turkish-named lib assets |
| Hero | `lib/assets/images/tarot_hero.webp` (pubspec) |
| Masters | pubspec notes unused PNG masters omitted (~167MB) |

**78-card face coverage for runtime webp: YES (22+56).**  
Duplicates and dual path roots are inventory risks for Visual System phase — do not regenerate here.

---

## J. Golden / visual test infrastructure

| Need | Classification | Notes |
|---|---|---|
| Flutter `matchesGoldenFile` Tarot suite | **MISSING** | no Tarot golden files found; only `release_golden_path_honesty_test` naming |
| Screenshot / reference capture | **PARTIAL** | e.g. hub reference capture at 390 |
| Tarot layout / entry tests | **PARTIAL** | `tarot_product_entry_test`, reveal/autosave reliability |
| 320 / 390 / large text / reduced motion | **PARTIAL** | strong elsewhere (settings/home); Tarot-specific locked set **MISSING** |
| Entry / Fan / Reveal / Mirror / Narrative / Recurring goldens | **MISSING** | |

**Golden infrastructure overall: PARTIAL → MISSING for locked Tarot acceptance set**

---

## K. Legacy / duplicate architecture

| Surface | Classification |
|---|---|
| `presentation/screens/reading_screen.dart` + `ai_reading/*` + ModuleRoot | **CURRENT PRODUCTION** |
| `presentation/epic031/*` | **CURRENT / PARTIAL** — entry body still imports epic031 title/cost/history/fan pieces |
| `ritual/*` table / flight | **CURRENT OR PARALLEL** — ritual scene still present; verify route dominance in Phase 1 (do not delete) |
| `widgets/*` (older result shells) | **LEGACY BUT REACHABLE** in places |
| `AiReadingCatalogue` canned content | **LEGACY / DEAD for paid AI path** |
| `card_reveal_spread` hardcoded sample assets | **LEGACY / SAMPLE risk** — inspect before Visual System |
| Dual asset roots (`assets/tarot` vs `lib/assets/images/tarot`) | **EXPERIMENTAL / DUPLICATE** inventory |
| Older reading engine vs AI executor | Local narrative = CURRENT for fallback/dev; AI = CURRENT production interpretation |

**Legacy Tarot surfaces identified: YES** — inventory required before Visual System; **no deletions in Phase 0.**

---

## L. Gap matrix

| Area | Status | Production reachability | Exact anchors | Future action |
|---|---|---|---|---|
| Narrative semantic profile | PARTIAL | data on cards; not Narrative Engine | `oracly_tarot_meanings.dart` | EXTEND |
| Card relationships | PARTIAL | local story + relatedIds | `oracly_tarot_relations.dart`, `reading_relations.dart` | EXTEND |
| Reversed semantics | PARTIAL | keywords + challengeMeaning + AI flag | bridge, executor payload | EXTEND |
| Spread semantics | PARTIAL | positions → AI labels | `tarot_spread_positions.dart` | EXTEND |
| Question grounding | PARTIAL | local strong; AI partial | `TarotIntention`, `ReadingAsk`, prompt | EXTEND |
| Narrative arc | PARTIAL | local `ReadingStory`; AI schema not arc-first | `reading_story.dart` | EXTEND / REPLACE result shape later |
| Memory grounding | PARTIAL | hints + memory optional | `JourneyPersonalizationHints` | EXTEND |
| Recurring cards | PARTIAL | recent names only | builder + AI payload | EXTEND |
| Recurring themes | PARTIAL | labels from insights | builder | EXTEND |
| Signature spread support | ABSENT | — | — | REPLACE/add later (Phase 5) |
| Result architecture | PARTIAL | fixed sections | `InterpretationResult`, `ReadingPremiumBody` | REPLACE LATER |
| Anti-generic quality | PARTIAL | `AiOutputQualityTarot` | quality gate | EXTEND |
| Anti-flattery | PARTIAL | reflective soften / quality | ReflectiveIntelligence | EXTEND |
| Uncertainty rules | PARTIAL | hedges, copy, quality | `reading_hedge`, FortuneVoice checks | EXTEND |
| Card visual system | PARTIAL | multi-stack UI | presentation/ritual/epic031 | EXTEND / unify |
| Card back identity | PARTIAL | SVG backs + painters | `OraclyTarotAssets`, painters | EXTEND |
| Fan | PARTIAL | epic031 / selection | epic031 fan | EXTEND |
| Reveal | PARTIAL | card_reveal | reveal widgets | EXTEND |
| Spread composition | PARTIAL | style layouts | spread_visual_style | EXTEND |
| Result hierarchy | ABSENT/WEAK | section body | ReadingPremiumBody | REPLACE LATER |
| Recurring-card UI | ABSENT | — | — | EXTEND later |
| Golden testing | MISSING | — | — | EXTEND (Phase 7) |
| Responsive | PARTIAL | some tests | entry 390 | EXTEND |
| A11y | PARTIAL | reduced motion hooks | ReadingScreen | EXTEND |
| Reduced motion | PARTIAL | reading path | OraclyReducedMotion | EXTEND |

---

## Phase 0 stop line

- **No Tarot implementation** performed.  
- **Narrative Tarot Engine:** NOT IMPLEMENTED.  
- **Tarot Visual System (locked goldens):** NOT IMPLEMENTED.  
- **Next:** ChatGPT / product-owner review of this baseline before Phase 1.
