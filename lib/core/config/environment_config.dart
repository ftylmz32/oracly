/// OR-1130 — Environment-specific runtime configuration.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_environment.dart';

/// Resolves API hosts and feature flags from environment variables.
class EnvironmentConfig {
  EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.enableLogging,
    required this.enableCertificatePinning,
    required this.syncIntervalSeconds,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String apiVersion;
  final bool enableLogging;
  final bool enableCertificatePinning;
  final int syncIntervalSeconds;

  static EnvironmentConfig fromEnv([Map<String, String>? env]) {
    final source = env ?? dotenv.env;
    final environment = AppEnvironment.fromString(source['APP_ENV']);
    final baseUrl = _resolveBaseUrl(environment, source);

    return EnvironmentConfig(
      environment: environment,
      apiBaseUrl: baseUrl,
      apiVersion: source['API_VERSION'] ?? 'v1',
      enableLogging: _parseBool(source['ENABLE_LOGGING'], defaultValue: !environment.isProduction),
      enableCertificatePinning: _parseBool(
        source['ENABLE_CERT_PINNING'],
        defaultValue: environment.isProduction,
      ),
      syncIntervalSeconds: int.tryParse(source['SYNC_INTERVAL_SECONDS'] ?? '') ?? 300,
    );
  }

  static String _resolveBaseUrl(AppEnvironment env, Map<String, String> source) {
    final override = source['API_BASE_URL'];
    if (override != null && override.isNotEmpty) return override;

    return switch (env) {
      AppEnvironment.development => source['DEV_API_BASE_URL'] ?? 'http://localhost:8080',
      AppEnvironment.staging => source['STAGING_API_BASE_URL'] ?? 'https://staging-api.oracly.app',
      AppEnvironment.production => source['PROD_API_BASE_URL'] ?? 'https://api.oracly.app',
    };
  }

  static bool _parseBool(String? value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }
}
