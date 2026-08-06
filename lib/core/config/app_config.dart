/// OR-1130 — Central application configuration bootstrap.
library;

import 'environment_config.dart';

/// Singleton access point for runtime configuration.
abstract final class AppConfig {
  static EnvironmentConfig? _config;

  static EnvironmentConfig get instance {
    final config = _config;
    if (config == null) {
      throw StateError('AppConfig.initialize() must be called before use.');
    }
    return config;
  }

  static bool get isInitialized => _config != null;

  static Future<void> initialize([EnvironmentConfig? config]) async {
    _config = config ?? EnvironmentConfig.fromEnv();
  }

  static void reset() => _config = null;
}
