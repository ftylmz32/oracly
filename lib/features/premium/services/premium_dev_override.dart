/// DEV-ONLY Premium unlock. Never a production backdoor.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/config/app_environment.dart';

/// Canonical developer entitlement override.
///
/// Active only when:
/// - not release (`kReleaseMode` false)
/// - `APP_ENV=development`
/// - `ORACLY_DEV_PREMIUM=true` (dart-define or local dotenv)
///
/// Production / staging / release always ignore this flag.
abstract final class PremiumDevOverride {
  PremiumDevOverride._();

  /// Local command (debug):
  /// `flutter run --dart-define=APP_ENV=development --dart-define=ORACLY_DEV_PREMIUM=true`
  static bool get isActive {
    if (kReleaseMode) return false;
    final env = _environment();
    if (!env.isDevelopment) return false;
    return _flagEnabled();
  }

  /// Back-compat for callers that checked the old compile-time switch.
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
    const define = String.fromEnvironment('APP_ENV');
    Map<String, String> env = const {};
    try {
      env = dotenv.env;
    } catch (_) {}
    return AppEnvironment.fromString(
      _first([define, env['APP_ENV']]) ??
          (kReleaseMode ? 'production' : 'development'),
    );
  }

  static bool _flagEnabled() {
    final override = debugFlag;
    if (override != null) return override;
    const define = String.fromEnvironment('ORACLY_DEV_PREMIUM');
    Map<String, String> env = const {};
    try {
      env = dotenv.env;
    } catch (_) {}
    final raw = (_first([define, env['ORACLY_DEV_PREMIUM']]) ?? '')
        .trim()
        .toLowerCase();
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }

  static String? _first(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
