/// Whether a NEW Coffee V3 operation may be started on this client right
/// now: the client rollout flag (default false) AND a Turkish UI. Never
/// consulted for an already-created V3 operation — flags block new
/// creation only, never recovery / polling / acceleration / result.
library;

import '../../../../core/feature_flags/feature_flag_rollback.dart';
import '../../../../core/feature_flags/feature_flag_surface.dart';
import '../../../../core/l10n/l10n.dart';

abstract final class CoffeeV3CreationGate {
  CoffeeV3CreationGate._();

  /// The frozen V3 interpretation stack is Turkish-only.
  static const requiredLanguage = 'tr';

  /// Explicit build-time rollout for store/internal builds. The backend keeps
  /// an independent authoritative creation gate with the same public key, so
  /// disabling server-side creation remains the immediate rollback path.
  static const buildRolloutEnabled = bool.fromEnvironment(
    'ORACLY_COFFEE_V3_ENABLED',
  );

  static bool get rolloutEnabled =>
      buildRolloutEnabled ||
      FeatureFlagRollback.useExperimental(FeatureFlagSurface.coffeeV3Capture);

  static bool get languageSupported => OraclyL10n.code == requiredLanguage;

  static bool get creationAllowed => rolloutEnabled && languageSupported;
}
