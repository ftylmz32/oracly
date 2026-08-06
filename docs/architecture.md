# ORACLY Architecture

**OR-438 — Future-ready reference.** Describes how to extend the app without structural rewrites.

## Layer map

```
lib/
├── app/                 # Bootstrap, Riverpod app providers
├── core/                # Shared infrastructure (preferred for cross-cutting code)
│   ├── domain/          # Models + repository interfaces
│   ├── data/            # Repository implementations
│   ├── services/        # Orchestration
│   ├── navigation/      # Routes, generator, navigation service
│   ├── theme/           # Design tokens → import oracly_design_system.dart
│   ├── modules/         # Feature registry + extension points (OR-438)
│   ├── l10n/            # String keys + Turkish table (pre-gen-l10n)
│   └── settings/        # SettingsSchema keys
├── features/            # Feature modules (preferred for new work)
├── shared/              # Cross-feature UI + tab shell
│   └── design/          # oracly_premium_kit.dart — reusable premium widgets
├── screens/             # Legacy — migrate when touching files
├── widgets/             # Legacy — prefer shared/widgets/
└── services/            # Legacy — prefer core/services/ or features/*/services/
```

## Active shell

Tab roots (`OraclyAppShell`): **Home** · **Tarot** · **Chat** · **Profile**

Named routes for modals and deep links: `OraclyRoutes` + `OraclyRouteGenerator` + `OraclyNavigationService`.

## Adding a new module (checklist)

Use this order — no UX change until steps 6–7 are intentionally shipped.

| Step | Action | Location |
|------|--------|----------|
| 1 | Register module descriptor | `core/modules/oracly_feature_registry.dart` |
| 2 | Add route constant | `core/navigation/oracly_routes.dart` |
| 3 | Wire route generator + nav method | `oracly_route_generator.dart`, `oracly_navigation_service.dart` |
| 4 | Engine (if AI-backed) | `OracleEngineType`, `OracleEngineFactory`, `RuleRegistry` |
| 5 | Prompts (if AI-backed) | `PromptDomain`, `prompt_engine/providers` |
| 6 | Content catalogue | `features/content/<id>/` + `content_providers.dart` |
| 7 | Persistence | `core/domain/models/`, repository, `backend_providers.dart` |
| 8 | UI | `features/<id>/presentation/` — start with `FeatureHubScreen` |
| 9 | Discovery | Home tile via `OraclyFeatureNavigation.open()` |

**Folder scaffold:** see `core/modules/oracly_feature_scaffold.dart`.

## Module registry (OR-438)

`OraclyFeatureRegistry` is the single catalogue of live, preview, and reserved modules.

- **Live** — fully navigable (Tarot, Chat, Daily Energy, …)
- **Preview** — hub screen exists (Dream, Astrology, Star Map)
- **Reserved** — architecture only (Numerology, Moon Calendar, Manifestation)

Query helpers: `byId`, `byRoute`, `forHomeBand`, `withEngine`.

Navigation bridge: `OraclyFeatureNavigation.open(context, id)` — delegates to existing nav APIs.

## Backend registries (already in place)

| Registry | Path |
|----------|------|
| Oracle engines | `features/oracle_engine/services/oracle_engine_factory.dart` |
| Prompt templates | `features/prompt_engine/templates/template_registry.dart` |
| Content repos | `features/content/providers/content_providers.dart` |

Numerology engine exists; UI route is reserved in `OraclyRoutes.numerology`.

## Design system

**One import for tokens:** `core/theme/oracly_design_system.dart`

**Premium UI kit for new modules:** `shared/design/oracly_premium_kit.dart`

Feature-specific extensions stay in `features/<module>/theme/` (e.g. tarot_tokens, home_composition).

## Data models

Pattern: `core/domain/models/` + `core/domain/repositories/` + `core/data/repositories/`

Journal / readings: `ReadingModel` + `RitualJournalMetadata` (OR-437).

Avoid duplicating domain models inside feature folders when a shared concept exists.

## Providers

| Scope | Location |
|-------|----------|
| App repos & notifiers | `app/providers/app_providers.dart` |
| Backend infra | `core/providers/backend_providers.dart` |
| Feature-specific | `features/<module>/providers/` |

**Naming:** app `readingHistoryProvider` = saved tarot readings.  
Oracle engine list = `oracleEngineReadingsProvider` (not `readingHistoryProvider`).

## Localization readiness

No `gen-l10n` yet. New copy should use:

1. `L10nKeys.*` — semantic key
2. `AppStringsTr.resolve(key)` or `OraclyL10n.t(key, languageCode: settings.language)`

Existing hardcoded Turkish in widgets is unchanged until incrementally migrated.

## Settings scalability

Global keys: `SettingsSchema` in `core/settings/settings_schema.dart`.

Module-owned keys are declared on `OraclyFeatureModule.settingsKeys` before UI exposes them.

Settings model currently lives in `features/premium/models/personalization_models.dart` — new global fields should eventually move to `core/domain`.

## Premium scalability

`OraclyFeatureModule.requiresPremium` flags paywalled modules.

Premium UI patterns: `features/premium/presentation/widgets/settings_tiles.dart` (glass list reference).

## Legacy migration (do when touching files)

| Legacy | Target |
|--------|--------|
| `lib/screens/` | `lib/features/<name>/presentation/screens/` |
| `lib/widgets/oracly_button.dart` | `lib/shared/widgets/oracly_button.dart` |
| `lib/services/` | `lib/core/services/` or feature services |

Do not mass-move files — migrate on contact.

## Future modules status

| Module | Engine | Route | UI |
|--------|--------|-------|-----|
| Tarot | ✅ | ✅ tab | ✅ full |
| Dream | ✅ | ✅ preview | stub |
| Astrology | ✅ | ✅ preview | stub |
| Numerology | ✅ | reserved | — |
| Moon Calendar | — | reserved | — |
| Manifestation | — | reserved | — |
