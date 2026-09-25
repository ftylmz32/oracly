# Tarot Phase 7A — Visual Forensic Baseline + Golden Architecture

**Status:** PASS candidate · Documentation + test-only harness  
**Date:** 2026-09-25  
**Branch:** `fix/final-product-remediation-20260922`  
**START HEAD:** `a48077dd80eb0427d458feecc9b92baba60abac8`  
**Phase 6:** FROZEN · Crossroads picker/live FALSE · Real provider calls: 0

---

## 1 — Purpose

Establish deterministic visual baselines and the canonical Tarot visual architecture **without** redesigning production screens or touching Narrative V2.

---

## 2 — Production journey (runtime)

```
OraclyRoutes.tarot
  → TarotModuleNavigator → TarotHomeScreen = TarotTableScene
  → intention overlay → spread overlay → preparing → draw/flight
  → reading overlay → optional deepen → ReadingScreen
  → OR follow-up / history reopen
```

**Parallel entry:** Daily / `startTarotFlow` (in-scope) → `/tarot/deck` → deck-ready → shuffle alias → same `TarotTableScene`.

**Owners:** `TarotFlowController` · `TarotReadingController` · `TarotRitualController` · `TarotTableSceneActions`

There is **no** `TarotController` / `TarotPhase` in this tree.

---

## 3 — Reachable surface inventory

### Canonical
| Surface | Path |
|---------|------|
| Home / table | `tarot_home_screen` → `TarotTableScene` |
| Intention / spread | table overlays |
| Deck-ready (parallel) | `TarotRitualDeckReadyScreen` |
| Shuffle alias | `ShuffleScreen` → table |
| Reading result | `ReadingScreen` + `ReadingPremium*` |
| History list/detail | `ReadingHistoryScreen` / `ReadingHistoryDetailScreen` |

### Transitional
Deck selection gate Path B; ritual intention/spread **routes** still registered but not opened by live home.

### Legacy reachable / orphan routes
`/tarot/intention` · `/tarot/spread` · `/tarot/destem` · `/tarot/card` (registered; no live openers)

### Dead / unreachable
epic031 page · old `tarot_home` cinematic stack · `CardSelectionScreen` / `CardRevealScreen` · `TarotRitualHost` · multi-deck picker widgets · `TarotBackground`

### Duplicate paths
Old multi-screen ritual pipeline vs single-table spine; `/tarot/select|reveal|draw` aliases all resolve to Shuffle/table.

---

## 4 — Visual system classification

| System | Class |
|--------|-------|
| TarotTokens · OraclyChrome · OraclyArtDirection · ReadingTypography · OraclySignatureMotion | **KEEP** |
| TarotTableBackground · RitualCardShell · DeckVisualState · ReadingPremium* | **KEEP** |
| TarotAtmosphere · SpreadVisualStyle / SacredIdentity / CardLiving · Reveal ambience | **LEGACY** (old home / dead reveal) |
| TarotBackground · DeckVisualStyle multi-deck cards · TarotGlassCard (shell-only) | **DEAD** / **LEGACY** |
| Reading result hierarchy toward Narrative-first | **EXTEND** (7E) |
| Competing chrome / old home painters | **CONSOLIDATE** (7B) |

**Owners:** Tokens=`tarot_tokens.dart` · Chrome=`oracly_chrome.dart` · Card=`ritual_card_shell` / art · Background live=`tarot_table_background` · Motion=`OraclySignatureMotion` · Result type=`ReadingTypography`

---

## 5 — Narrative result UI forensic

| Question | Finding |
|----------|---------|
| Primary body | Hero story = `luckyEnergy` else `generalMeaning` |
| Love/Career/Money | Demoted expandable detail layers (not hero) |
| `fullInterpretation` | Persist/share only — not in scroll hierarchy |
| Cards | Art strip + expandable text tiles (duplication) |
| Question | Header when `ReadingQuestion.real` |
| Relationships | Local adjacent-pair prose — not Evidence edges |
| Recurrence/memory | **ABSENT** from result UI |
| Closing | Direction section + footer whisper |
| OR follow-up | Footer `onAskOracle` |
| Main debt | Legacy schema still fills life areas; strip ignores Signature geometry; no memory UI |

UI adapts to frozen Narrative contract — do **not** change domain contracts in Phase 7.

---

## 6 — Geometry

| Spread | Hook | Public |
|--------|------|--------|
| single | `single` | yes |
| threeCard | `threeLinear` | yes |
| fiveCard | `fiveLinear` | yes |
| sevenCard | (catalog; no SpreadVisualStyle) | gated by flag |
| celticCross | home preview painter only | not ritual allowlist |
| Crossroads | **`fiveDecision`** (decisionBranching) | **NO** |

Crossroads is **not** remapped to fiveCard. Picker/live remain false.

---

## 7 — Golden infrastructure (7A)

| Item | Value |
|------|-------|
| Existing | Hub `RepaintBoundary` capture · result long-text viewport tests · **no** `matchesGoldenFile` Tarot suite |
| New | `test/visual/tarot/` harness + fixtures + baselines + geometry contract |
| Canonical viewport | 390×844 |
| Secondary | 320×568 · 412×915 · 360×800 @ textScale 1.3 |
| Animation | Settled frames only (`pump` + 16ms) |
| Capture | Opt-in `TAROT_VISUAL_CAPTURE=1` → `design/runtime/tarot/` |
| Network/provider | **Never** |

### Golden policy
1. **Structural** — hierarchy, clipping, CTA, SafeArea (CI default)  
2. **Pixel** — opt-in settled PNGs where stable  
3. **Behavior** — scroll, text-scale, semantics, interaction (existing suites)

---

## 8 — Performance risks (inventory)

| Risk | Examples |
|------|----------|
| Blur | `ReadingPremiumBody` ImageFilter · glass panels · old home BackdropFilter |
| Particles | `ReadingFloatingParticles` · deck ambience painters |
| CustomPainters | Table celestial · cinematic background · dead home sanctuary painters |
| Low-end | Nested blur + particles on 320×568 |

**Budget target:** 60 FPS on changed surfaces; max one ambient loop per screen (OOS).

---

## 9 — Accessibility contract

- Touch targets ≥ 44 logical px  
- Readable cream-on-dark contrast  
- Text scale 1.3 without broken layout  
- Semantics on critical actions  
- Reduced / constrained motion for ritual  
- No content under nav / SafeArea  

---

## 10 — Assets

| Root | Role |
|------|------|
| `lib/assets/images/tarot/` (+ thumbs, card back) | Runtime card art |
| `lib/assets/images/tarot_hero.webp` | Feature hero |
| `assets/tarot/` (brand/card_back/logo/cards) | Parallel/legacy asset tree |
| `features/tarot_art/` | Design masters / DNA (not shipping) |

**7A:** no deletion · no regeneration · no production art swap.

---

## 11 — Phase 6 firewall

Narrative / backend / billing / model / live routing / Crossroads exposure: **unchanged** in 7A.

---

## 12 — Phase 7 slices

See `TAROT_PHASE7_IMPLEMENTATION_SLICES.md` and `TAROT_PHASE7_VISUAL_CONTRACT.md`.
