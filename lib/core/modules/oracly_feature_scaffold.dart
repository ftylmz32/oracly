/// OR-438 — Folder scaffold for new feature modules.
///
/// Recommended layout (matches tarot + content patterns):
///
/// ```
/// lib/features/<module_id>/
///   domain/           # models, repository interfaces
///   data/             # local/remote implementations
///   services/         # orchestration
///   providers/        # Riverpod (keep app_providers thin)
///   presentation/
///     screens/
///     widgets/
///   navigation/       # optional nested navigator
///   theme/            # module tokens extending core/theme
/// ```
///
/// Registration checklist (no UX change until wired):
/// 1. [OraclyFeatureRegistry] — add [OraclyFeatureModule]
/// 2. [OraclyRoutes] + [OraclyRouteGenerator] + [OraclyNavigationService]
/// 3. [OracleEngineFactory] + [PromptDomain] if AI-backed
/// 4. `features/content/<id>/` catalogue + [content_providers]
/// 5. `core/domain` model + repository + [backend_providers]
/// 6. Home tile via [OraclyFeatureNavigation] or [MysticFeatureGrid]
///
/// Prefer [FeatureHubScreen] for preview-phase modules.
/// Import UI from `shared/design/oracly_premium_kit.dart`.
library;

/// Marker type — new modules may `implements OraclyFeatureScaffold` in docs/tests.
abstract interface class OraclyFeatureScaffold {
  String get moduleId;
}
