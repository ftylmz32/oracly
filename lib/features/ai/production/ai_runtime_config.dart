/// Runtime AI config — never logs secrets, never hardcodes keys.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/config/oracly_runtime_config.dart';
import '../../../core/config/oracly_runtime_keys.dart';
import '../../../core/config/release_endpoint_policy.dart';
import '../../../core/security/api_key_provider.dart';
import 'ai_proxy_url_policy.dart';

class AiRuntimeConfig {
  const AiRuntimeConfig({
    this.environment = AppEnvironment.development,
    this.proxyUrl,
    this.openAiKey,
    this.model = defaultModel,
    this.timeout = defaultTimeout,
    this.imageTimeout = defaultImageTimeout,
    this.visionEnabled = true,
    @visibleForTesting this.simulateReleaseBuild = false,
  });

  static const defaultModel = 'gpt-4o';
  static const defaultTimeout = Duration(seconds: 45);
  /// GPT Image generation may approach ~2 minutes.
  static const defaultImageTimeout = Duration(seconds: 120);
  static const openAiChatUrl = 'https://api.openai.com/v1/chat/completions';
  static const localDevProxyUrl = 'http://127.0.0.1:8787/v1/ai/complete';
  /// Android emulator maps host loopback to 10.0.2.2 (not 127.0.0.1).
  static const androidEmulatorDevProxyUrl =
      'http://10.0.2.2:8787/v1/ai/complete';

  final AppEnvironment environment;
  final String? proxyUrl;
  final String? openAiKey;
  final String model;
  final Duration timeout;
  final Duration imageTimeout;
  final bool visionEnabled;
  final bool simulateReleaseBuild;

  bool get _releaseLocked => kReleaseMode || simulateReleaseBuild;

  String? get resolvedProxyUrl => AiProxyUrlPolicy.sanitize(
        raw: proxyUrl,
        isDevelopment: environment.isDevelopment,
        releaseLocked: _releaseLocked,
      );

  bool get usesProxy => (resolvedProxyUrl ?? '').isNotEmpty;

  bool get allowsClientOpenAiKey =>
      environment.isDevelopment && !_releaseLocked;

  bool get usesClientKey =>
      !usesProxy &&
      allowsClientOpenAiKey &&
      (openAiKey ?? '').trim().isNotEmpty;

  bool get isConfigured => usesProxy || usesClientKey;
  bool get visionAvailable => isConfigured && visionEnabled;

  bool get allowsLocalFallback =>
      !isConfigured && environment.isDevelopment && !_releaseLocked;

  String get safeEnvironmentLabel => environment.isStaging
      ? 'INTERNAL'
      : environment.isProduction
          ? 'PRODUCTION'
          : 'LOCAL';

  String get safeHostLabel {
    final raw = resolvedProxyUrl;
    if (raw == null) return 'unconfigured';
    return Uri.tryParse(raw)?.host ?? 'invalid';
  }

  String get safeTransportLabel => usesProxy
      ? (ReleaseEndpointPolicy.isLoopbackUrl(resolvedProxyUrl) ||
              ReleaseEndpointPolicy.isPrivateOrLanUrl(resolvedProxyUrl)
          ? 'local-proxy'
          : 'remote-proxy')
      : usesClientKey
          ? 'direct-development'
          : 'unconfigured';

  @visibleForTesting
  static bool loopbackProxyAutoDefaultAllowed({
    TargetPlatform? platform,
    bool? isWeb,
  }) {
    if (isWeb ?? kIsWeb) return true;
    final p = platform ?? defaultTargetPlatform;
    return p != TargetPlatform.android && p != TargetPlatform.iOS;
  }

  /// Dev-only proxy URL when [ORACLY_AI_PROXY_URL] is unset.
  @visibleForTesting
  static String? devProxyAutoDefaultUrl({
    TargetPlatform? platform,
    bool? isWeb,
  }) {
    if (isWeb ?? kIsWeb) return localDevProxyUrl;
    final p = platform ?? defaultTargetPlatform;
    return switch (p) {
      TargetPlatform.android => androidEmulatorDevProxyUrl,
      TargetPlatform.iOS => localDevProxyUrl,
      _ => localDevProxyUrl,
    };
  }

  @override
  String toString() =>
      'AiRuntimeConfig(env: ${environment.name}, model: $model, '
      'proxy: $usesProxy, clientKey: ${usesClientKey ? 'present' : 'absent'}, '
      'vision: $visionAvailable, timeoutMs: ${timeout.inMilliseconds}, '
      'imageTimeoutMs: ${imageTimeout.inMilliseconds})';

  factory AiRuntimeConfig.resolve({ApiKeyProvider? keys}) {
    Map<String, String> env = const {};
    try {
      env = dotenv.env;
    } catch (_) {}
    final runtime = OraclyRuntimeConfig.resolve();
    final environment = runtime.environment;
    final rawEnvironment =
        OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.appEnv)
            ?.trim()
            .toLowerCase();
    final explicitLocal = rawEnvironment == 'local';
    final key = environment.isDevelopment && !kReleaseMode
        ? _first([keys?.openAiKey, env['OPENAI_API_KEY']])
        : null;
    final visionRaw = (runtime.aiVision ?? 'true').toLowerCase();
    var proxyUrl = runtime.aiProxyUrl;
    // Loopback is available only after an explicit APP_ENV=local selection.
    if (!kReleaseMode && environment.isDevelopment && explicitLocal) {
      proxyUrl = OraclyRuntimeConfig.readRaw(OraclyRuntimeKeys.aiProxyUrl);
      if (proxyUrl == null && !const bool.fromEnvironment('FLUTTER_TEST')) {
        proxyUrl = devProxyAutoDefaultUrl();
      }
      proxyUrl = AiProxyUrlPolicy.sanitize(
        raw: proxyUrl,
        isDevelopment: true,
        releaseLocked: false,
      );
    } else if (environment.isDevelopment) {
      proxyUrl = null;
    }
    return AiRuntimeConfig(
      environment: environment,
      proxyUrl: AiProxyUrlPolicy.sanitize(
        raw: proxyUrl,
        isDevelopment: environment.isDevelopment,
        releaseLocked: kReleaseMode,
      ),
      openAiKey: key,
      model: runtime.aiModel ?? defaultModel,
      timeout: Duration(
        seconds: (int.tryParse(runtime.aiTimeoutSeconds ?? '') ??
                defaultTimeout.inSeconds)
            .clamp(15, 90),
      ),
      imageTimeout: Duration(
        seconds: (int.tryParse(
                    OraclyRuntimeConfig.readRaw(
                          OraclyRuntimeKeys.aiImageTimeoutSeconds,
                        ) ??
                        '',
                  ) ??
                  defaultImageTimeout.inSeconds)
            .clamp(30, 180),
      ),
      visionEnabled: visionRaw != 'false' && visionRaw != '0',
    );
  }

  static String? _first(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
