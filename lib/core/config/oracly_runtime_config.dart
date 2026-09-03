/// Canonical client runtime config — one place for dart-define / dotenv reads.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_environment.dart';
import 'oracly_runtime_keys.dart';
import 'release_endpoint_policy.dart';

class OraclyRuntimeConfig {
  const OraclyRuntimeConfig({
    required this.environment,
    required this.releaseLocked,
    this.aiProxyUrl,
    this.billingVerifyUrl,
    this.privacyPolicyUrl,
    this.termsOfUseUrl,
    this.aiModel,
    this.aiTimeoutSeconds,
    this.aiVision,
    this.devPremiumRaw,
  });

  final AppEnvironment environment;
  final bool releaseLocked;
  final String? aiProxyUrl;
  final String? billingVerifyUrl;
  final String? privacyPolicyUrl;
  final String? termsOfUseUrl;
  final String? aiModel;
  final String? aiTimeoutSeconds;
  final String? aiVision;
  final String? devPremiumRaw;

  bool get hasAiProxy => (aiProxyUrl ?? '').isNotEmpty;
  bool get hasBillingVerify => (billingVerifyUrl ?? '').isNotEmpty;

  List<String> get missingMandatoryReleaseKeys {
    final missing = <String>[];
    if (!hasAiProxy) missing.add(OraclyRuntimeKeys.aiProxyUrl);
    if (!hasBillingVerify) missing.add(OraclyRuntimeKeys.billingVerifyUrl);
    return missing;
  }

  bool get isReleaseConfigComplete => missingMandatoryReleaseKeys.isEmpty;

  static const internalBackendBaseUrl =
      'https://r31b-200bc15b---oracly-api-uya7zqzwra-ew.a.run.app';
  static const internalAiProxyUrl = '$internalBackendBaseUrl/v1/ai/complete';
  static const internalBillingVerifyUrl =
      '$internalBackendBaseUrl/v1/billing/verify';

  static Map<String, String>? testEnv;

  static String? readRaw(String key) {
    final fromTest = testEnv?[key]?.trim();
    if (fromTest != null && fromTest.isNotEmpty) return fromTest;

    final define = switch (key) {
      OraclyRuntimeKeys.appEnv => const String.fromEnvironment('APP_ENV'),
      OraclyRuntimeKeys.aiProxyUrl => const String.fromEnvironment(
        'ORACLY_AI_PROXY_URL',
      ),
      OraclyRuntimeKeys.billingVerifyUrl => const String.fromEnvironment(
        'ORACLY_BILLING_VERIFY_URL',
      ),
      OraclyRuntimeKeys.aiModel => const String.fromEnvironment(
        'ORACLY_AI_MODEL',
      ),
      OraclyRuntimeKeys.aiTimeoutSeconds => const String.fromEnvironment(
        'ORACLY_AI_TIMEOUT_SECONDS',
      ),
      OraclyRuntimeKeys.aiVision => const String.fromEnvironment(
        'ORACLY_AI_VISION',
      ),
      OraclyRuntimeKeys.privacyPolicyUrl => const String.fromEnvironment(
        'ORACLY_PRIVACY_POLICY_URL',
      ),
      OraclyRuntimeKeys.termsOfUseUrl => const String.fromEnvironment(
        'ORACLY_TERMS_OF_USE_URL',
      ),
      OraclyRuntimeKeys.devPremium => const String.fromEnvironment(
        'ORACLY_DEV_PREMIUM',
      ),
      _ => '',
    };
    if (define.trim().isNotEmpty) return define.trim();

    Map<String, String> env = const {};
    try {
      env = dotenv.env;
    } catch (_) {}
    final fromDot = env[key]?.trim();
    if (fromDot != null && fromDot.isNotEmpty) return fromDot;
    return null;
  }

  factory OraclyRuntimeConfig.resolve({bool? releaseLocked}) {
    final locked = releaseLocked ?? kReleaseMode;
    final rawEnvironment = readRaw(OraclyRuntimeKeys.appEnv)?.toLowerCase();
    final environment = AppEnvironment.fromString(
      rawEnvironment ?? (locked ? 'production' : null),
    );
    final isInternal = rawEnvironment == 'internal';
    final isDev = environment.isDevelopment;
    String? endpoint(String key) => ReleaseEndpointPolicy.sanitize(
      raw: readRaw(key),
      isDevelopment: isDev,
      releaseLocked: locked,
    );

    return OraclyRuntimeConfig(
      environment: environment,
      releaseLocked: locked,
      aiProxyUrl: isInternal
          ? internalAiProxyUrl
          : endpoint(OraclyRuntimeKeys.aiProxyUrl),
      billingVerifyUrl: isInternal
          ? internalBillingVerifyUrl
          : endpoint(OraclyRuntimeKeys.billingVerifyUrl),
      privacyPolicyUrl: _publicDoc(
        ReleaseEndpointPolicy.sanitize(
          raw: readRaw(OraclyRuntimeKeys.privacyPolicyUrl),
          isDevelopment: false,
          releaseLocked: true,
        ),
      ),
      termsOfUseUrl: _publicDoc(
        ReleaseEndpointPolicy.sanitize(
          raw: readRaw(OraclyRuntimeKeys.termsOfUseUrl),
          isDevelopment: false,
          releaseLocked: true,
        ),
      ),
      aiModel: readRaw(OraclyRuntimeKeys.aiModel),
      aiTimeoutSeconds: readRaw(OraclyRuntimeKeys.aiTimeoutSeconds),
      aiVision: readRaw(OraclyRuntimeKeys.aiVision),
      devPremiumRaw: readRaw(OraclyRuntimeKeys.devPremium),
    );
  }

  static String? _publicDoc(String? url) {
    if (url == null) return null;
    final lower = url.toLowerCase();
    if (lower.contains('example.com') || lower.contains('placeholder')) {
      return null;
    }
    return url;
  }
}
