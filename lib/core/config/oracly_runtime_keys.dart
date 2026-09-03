/// Canonical Flutter client dart-define / dotenv keys.
library;

enum OraclyRuntimeKeyClass { mandatoryRelease, optionalRelease, debugOnly }

class OraclyRuntimeKey {
  const OraclyRuntimeKey(this.name, this.classification);

  final String name;
  final OraclyRuntimeKeyClass classification;
}

abstract final class OraclyRuntimeKeys {
  OraclyRuntimeKeys._();

  static const appEnv = 'APP_ENV';
  static const aiProxyUrl = 'ORACLY_AI_PROXY_URL';
  static const billingVerifyUrl = 'ORACLY_BILLING_VERIFY_URL';
  static const aiModel = 'ORACLY_AI_MODEL';
  static const aiTimeoutSeconds = 'ORACLY_AI_TIMEOUT_SECONDS';
  static const aiImageTimeoutSeconds = 'ORACLY_AI_IMAGE_TIMEOUT_SECONDS';
  static const aiVision = 'ORACLY_AI_VISION';
  static const privacyPolicyUrl = 'ORACLY_PRIVACY_POLICY_URL';
  static const termsOfUseUrl = 'ORACLY_TERMS_OF_USE_URL';
  static const devPremium = 'ORACLY_DEV_PREMIUM';
  static const openAiApiKey = 'OPENAI_API_KEY';

  /// Public client keys only — never secrets.
  static const catalog = <OraclyRuntimeKey>[
    OraclyRuntimeKey(appEnv, OraclyRuntimeKeyClass.mandatoryRelease),
    OraclyRuntimeKey(aiProxyUrl, OraclyRuntimeKeyClass.mandatoryRelease),
    OraclyRuntimeKey(billingVerifyUrl, OraclyRuntimeKeyClass.mandatoryRelease),
    OraclyRuntimeKey(aiModel, OraclyRuntimeKeyClass.optionalRelease),
    OraclyRuntimeKey(aiTimeoutSeconds, OraclyRuntimeKeyClass.optionalRelease),
    OraclyRuntimeKey(
      aiImageTimeoutSeconds,
      OraclyRuntimeKeyClass.optionalRelease,
    ),
    OraclyRuntimeKey(aiVision, OraclyRuntimeKeyClass.optionalRelease),
    OraclyRuntimeKey(privacyPolicyUrl, OraclyRuntimeKeyClass.optionalRelease),
    OraclyRuntimeKey(termsOfUseUrl, OraclyRuntimeKeyClass.optionalRelease),
    OraclyRuntimeKey(devPremium, OraclyRuntimeKeyClass.debugOnly),
    OraclyRuntimeKey(openAiApiKey, OraclyRuntimeKeyClass.debugOnly),
  ];

  static List<String> get mandatoryReleaseNames => catalog
      .where((k) => k.classification == OraclyRuntimeKeyClass.mandatoryRelease)
      .map((k) => k.name)
      .toList(growable: false);

  static List<String> get forbiddenClientSecretNames => const [
        openAiApiKey,
        'GOOGLE_SERVICE_ACCOUNT',
        'APPLE_PRIVATE_KEY',
        'PRIVATE_KEY',
      ];
}