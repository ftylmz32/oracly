/// OR-1130 — Environment-specific runtime configuration.
library;

import 'package:flutter/foundation.dart';
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
    // Release may skip dotenv.load; never throw NotInitializedError on cold start.
    Map<String, String> source = env ?? const {};
    if (env == null) {
      try {
        source = Map<String, String>.from(dotenv.env);
      } catch (_) {
        source = const {};
      }
    }
    final environment = AppEnvironment.fromString(
      source['APP_ENV'] ?? (kReleaseMode ? 'production' : null),
    );
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

  static const _productionFallback = 'https://api.oracly.app';

  static String _resolveBaseUrl(AppEnvironment env, Map<String, String> source) {
    final override = source['API_BASE_URL'];
    final raw = (override != null && override.isNotEmpty)
        ? override
        : switch (env) {
            AppEnvironment.development =>
              source['DEV_API_BASE_URL'] ?? 'http://localhost:8080',
            AppEnvironment.staging =>
              source['STAGING_API_BASE_URL'] ?? 'https://staging-api.oracly.app',
            AppEnvironment.production =>
              source['PROD_API_BASE_URL'] ?? _productionFallback,
          };
    return _lockReleaseApiBase(raw, env);
  }

  /// Release / production must not inherit localhost, LAN, or plain HTTP.
  static String _lockReleaseApiBase(String raw, AppEnvironment env) {
    if (!kReleaseMode && !env.isProduction) return raw;
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _productionFallback;
    }
    if (uri.scheme.toLowerCase() != 'https') return _productionFallback;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '0.0.0.0' ||
        host.endsWith('.local')) {
      return _productionFallback;
    }
    return trimmed;
  }

  static bool _parseBool(String? value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }
}
