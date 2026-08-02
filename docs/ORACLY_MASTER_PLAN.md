# Oracly Master Plan

Long-term development guide for the Oracly Flutter app — an AI-powered mystic companion (tarot, chat, memory, profile).

---

## Project Vision

Oracly is a **personal AI destiny assistant** that combines:

- **Conversational AI** — contextual chat powered by user profile and memory
- **Tarot readings** — interactive card draws with AI interpretation
- **Persistent memory** — learns and recalls user goals, interests, and context
- **Spirit Pulse** — daily energy / mood surface on the home screen

**Product principles**

1. Warm, mystical UI with a consistent cosmic/glass design language
2. Privacy-first local storage (SharedPreferences) with optional AI enrichment
3. Feature modules that can evolve independently without duplicating widgets or services
4. Turkish-first UX copy; code and identifiers in English

**Success criteria**

- Clean analyzer pass on every merge
- No duplicate widgets or dead placeholder files
- Each feature owns its screens, widgets, and services under `lib/features/`
- AI integrations are isolated in `*Service` classes, not in widgets

---

## Architecture Overview

```
lib/
├── main.dart                 # App entry, theme, splash
├── core/                     # Shared design system (theme, constants)
├── models/                   # Cross-feature domain models
├── services/                 # Cross-feature services (AI, memory, storage)
├── widgets/                  # Shared UI primitives (GlassCard, CosmicBackground)
├── features/                 # Feature modules (preferred for new work)
│   ├── home/
│   ├── tarot/
│   └── memory/
└── screens/                  # Legacy screens (migrate into features over time)
    ├── ai/
    ├── profile/
    ├── memory/
    ├── settings/
    ├── history/
    ├── privacy/
    └── splash/
```

**Layers**

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| **Screen** | Route, scaffold, navigation, local UI state | `TarotSelectScreen`, `ChatScreen` |
| **View / Section** | Composed layout, no business logic | `HomeView`, `EnergySection` |
| **Widget** | Reusable UI, minimal logic | `GlassCard`, `TarotResultCard` |
| **Controller** | `ChangeNotifier` state (when adopted) | `MemoryController`, `TarotController` |
| **Service** | IO, API, persistence | `AiService`, `DeckService` |
| **Model** | Immutable data + serialization | `MemoryItem`, `TarotCard` |
| **Data** | Static catalogs | `major_arcana.dart`, suit files |

**Navigation (current)** — imperative `Navigator.push` / `MaterialPageRoute`.  
**Target** — centralized routing (e.g. GoRouter) in a later phase.

**State (current)** — `StatefulWidget` + service instances per screen.  
**Target** — feature controllers or Riverpod/Provider where shared state is needed.

---

## Feature Roadmap

| Phase | Feature | Status | Notes |
|-------|---------|--------|-------|
| ✅ | Splash → Home | Done | `SplashScreen` → `HomeScreen` / `HomeView` |
| ✅ | Home dashboard | Done | Greeting, memory preview, Spirit Pulse, quick actions |
| ✅ | AI Chat | Done | OpenAI via `AiService`, history in `StorageService` |
| ✅ | Memory (CRUD partial) | In progress | Add/delete/search; edit sheet exists but not wired |
| ✅ | Profile | Done | Large screen; candidate for split |
| ✅ | Settings / Privacy / History | Done | Entry from quick actions or settings |
| 🔄 | Tarot select + draw | Done | `TarotSelectScreen`, `TarotDeck`, `DeckService` |
| 🔄 | Tarot reading UI | Done | `TarotResultCards`, `TarotReadingSection` |
| ⏳ | Tarot AI reading | Planned | Wire `tarot_ai_service.dart` (scaffold kept) |
| ⏳ | Tarot memory | Planned | Wire `tarot_memory_service.dart` |
| ⏳ | Tarot animations | Planned | Populate animation scaffolds |
| ⏳ | Astroloji | Placeholder | SnackBar “yakında” |
| ⏳ | Rüyalar | Not started | — |
| ⏳ | Home refresh | Planned | `HomeView._refresh` is stub |
| ⏳ | Legacy cleanup | Planned | Remove `lib/widgets/home/*`, unused shared widgets |
| ⏳ | Routing + DI | Planned | GoRouter, inject services |

---

## Module Checklist

### Core (`lib/core/`)

- [x] `theme/` — colors, spacing, radius, gradients, shadows, text styles, theme
- [ ] `constants/` — populate or merge into `theme/` (remove empty duplicates)

### Shared (`lib/widgets/`, `lib/services/`, `lib/models/`)

- [x] `GlassCard`, `CosmicBackground`, `MessageBubble`, `ChatInput`
- [x] `MemoryItem`, `AiService`, `MemoryService`, `StorageService`, `ProfileService`
- [ ] Remove duplicate/unused: `widgets/home/*`, `feature_card`, `section_title`, legacy `greeting_section`
- [ ] Add `Profile`, `ChatMessage` models (replace raw maps)

### Home (`lib/features/home/`)

- [x] `HomeScreen`, `HomeView`, sections, quick actions
- [ ] `HomeController` for pull-to-refresh
- [ ] Wire or remove `EnergyChip`

### Memory (`lib/features/memory/` + `lib/screens/memory/`)

- [x] List, search, add, delete
- [ ] Wire `MemoryController`, `EditMemorySheet`, `EmptyMemoryView`
- [ ] Consolidate screen under `features/memory/screens/`

### Tarot (`lib/features/tarot/`)

- [x] 78-card data, `DeckService`, select + reading screens
- [x] Result widgets: `TarotResultCard`, `TarotResultCards`, `TarotReadingSection`
- [ ] Implement `tarot_ai_service.dart`
- [ ] Implement `spread_service.dart` + use `TarotSpread` / `TarotPosition`
- [ ] Wire `TarotController` + phase/state machine
- [ ] Populate animation files or delete if deferred
- [ ] Split large data files if they exceed policy (data exception documented)

### Chat (`lib/screens/ai/`)

- [x] Functional chat
- [ ] Profile-driven greeting (remove hardcoded name)
- [ ] Move to `lib/features/chat/`

### Profile / Settings / History / Privacy

- [x] Functional
- [ ] Split `profile_screen.dart` (825 lines → sections)
- [ ] Migrate under `lib/features/`

---

## Folder Organization

**Rules**

1. **New features** → `lib/features/<name>/` with `screens/`, `widgets/`, `services/`, `models/` as needed
2. **Shared primitives** → `lib/widgets/` and `lib/core/theme/` only when used by 2+ features
3. **No duplicate widget names** across `lib/widgets/` and `lib/features/*/widgets/`
4. **No empty `.dart` files** — implement or delete in the same PR
5. **Assets** → `assets/images/cards/tarot/...` mirroring data file paths

**Target tarot layout (stable)**

```
lib/features/tarot/
├── animations/       # Flip, shuffle, spread (implement when ready)
├── data/             # major_arcana + suits (static catalogs)
├── models/           # TarotCard, TarotPhase, TarotState, TarotSpread, TarotPosition
├── screens/          # tarot_select_screen, tarot_reading_screen
├── services/         # deck_service, tarot_ai_service, spread_service, tarot_memory_service
├── utils/            # tarot_constants, tarot_helpers
└── widgets/          # deck, selectors, result + reading sections
```

---

## Coding Standards

### File size

- **Max 150 lines** per Dart file (excluding generated code)
- Exceptions: static data catalogs (`major_arcana.dart`, suit files) — split by arcana/suit only, never mix with UI

### Widgets

- Compose screens from **sections** and **existing widgets**
- Prefer `GlassCard`, `AppColors`, `AppSpacing`, `AppTextStyles`
- No inline duplicate of `TarotResultCard`-style layouts

### Services

- One public responsibility per service
- No `BuildContext` in services
- API keys via `.env` / `flutter_dotenv`

### Imports

- Package imports for Flutter; relative imports within a feature
- No unused imports; run `flutter analyze` before PR

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private members: `_leadingUnderscore`

### Localization

- User-facing strings: Turkish (centralize in `app_strings.dart` over time)
- Code comments: English or Turkish, consistent per file

---

## Definition of Done

A task is **done** when all of the following are true:

1. **`flutter analyze`** — zero issues project-wide
2. **Scope** — only files required for the task were changed
3. **No regressions** — splash → home → affected feature path manually verified
4. **No new duplicates** — grep confirms no second widget/service for the same purpose
5. **No empty files** — no new 0-byte or stub-only Dart files
6. **File size** — new/edited files ≤ 150 lines (or split with justification)
7. **Composition** — large `build()` methods extracted to widgets/sections
8. **Docs** — update this plan or feature checklist if architecture shifted

---

## Development Phases

### Phase 0 — Foundation ✅

Theme system, splash, home shell, shared widgets.

### Phase 1 — Tarot UI stability ✅

Fix reading screen; compose `TarotResultCards` + `TarotReadingSection`; Option B cleanup (remove confirmed dead tarot files).

### Phase 2 — Tarot AI ⏳

Implement `TarotAiService`; replace hardcoded reading in `tarot_reading_screen.dart`; optional `TarotMemoryService`.

### Phase 3 — Memory polish ⏳

Wire `MemoryController`, edit flow, empty state; consolidate under `features/memory`.

### Phase 4 — Legacy consolidation ⏳

Delete duplicate home widgets; migrate `screens/` → `features/`; populate or remove empty `core/constants/`.

### Phase 5 — Architecture hardening ⏳

GoRouter, dependency injection, shared models (`Profile`, `ChatMessage`), widget tests for critical paths.

### Phase 6 — New modalities ⏳

Astroloji, rüyalar, enhanced Spirit Pulse (real data vs mock).

---

## Priority Order

Work in this order unless blocked:

1. **Analyzer clean** — never merge broken builds
2. **Tarot AI service** — highest user-visible gap after draw flow
3. **Memory edit + controller** — sheet already built
4. **Profile screen split** — maintainability (825 lines)
5. **Home refresh + controller** — complete dashboard loop
6. **Legacy widget deletion** — `lib/widgets/home/*`, unused shared widgets
7. **`core/constants` merge** — single design-token source
8. **Routing migration** — GoRouter
9. **Chat feature module move** — `features/chat/`
10. **New features** — astroloji, rüyalar

---

## References

- Cursor agent rules: `.cursor/rules/oracly.mdc`
- Entry: `lib/main.dart` → `SplashScreen` → `HomeScreen`
- Tarot entry: `QuickActionsGrid` → `TarotSelectScreen`

*Last updated: August 2026*
