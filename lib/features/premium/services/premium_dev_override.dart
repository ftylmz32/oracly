/// DEV-ONLY Premium unlock. Never a production backdoor.
library;

import 'package:flutter/foundation.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/config/oracly_runtime_config.dart';
import '../../../core/config/oracly_runtime_keys.dart';

/// Active only when **all** of:
/// - [kDebugMode] (never profile / release)
/// - [AppEnvironment.development]
/// - [ORACLY_DEV_PREMIUM] enabled (`true`/`1`/`yes`/`on`)
///
/// Does not rewrite PremiumGrantPolicy. Does not persist store membership.
abstract final class PremiumDevOverride {
  PremiumDevOverride._();

  static bool get isActive {
    return allowsOverride(
      debugBuild: kDebugMode,
      environment: _environment(),
      flagEnabled: _flagEnabled(),
    );
  }

  /// Testable form of the compile-mode lock. Profile and release both pass
  /// [debugBuild] as false and can never activate the override.
  @visibleForTesting
  static bool allowsOverride({
    required bool debugBuild,
    required AppEnvironment environment,
    required bool flagEnabled,
  }) {
    return debugBuild && environment.isDevelopment && flagEnabled;
  }

  static bool get enabled => isActive;

  @visibleForTesting
  static AppEnvironment? debugEnvironment;

  @visibleForTesting
  static bool? debugFlag;

  @visibleForTesting
  static void resetDebug() {
    debugEnvironment = null;
    debugFlag = null;
  }

  static AppEnvironment _environment() {
    final override = debugEnvironment;
    if (override != null) return override;
    return AppEnvironment.fromString(
      OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.appEnv) ??
          (kDebugMode ? 'development' : 'production'),
    );
  }

  static bool _flagEnabled() {
    final override = debugFlag;
    if (override != null) return override;
    final raw =
        (OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.devPremium) ?? '')
            .trim()
            .toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }
}
