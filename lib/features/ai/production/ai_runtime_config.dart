/// Runtime AI config — never logs secrets, never hardcodes keys.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/security/api_key_provider.dart';
import 'ai_proxy_url_policy.dart';

class AiRuntimeConfig {
  const AiRuntimeConfig({
    this.environment = AppEnvironment.development,
    this.proxyUrl,
    this.openAiKey,
    this.model = defaultModel,
    this.timeout = defaultTimeout,
    this.visionEnabled = true,
    @visibleForTesting this.simulateReleaseBuild = false,
  });

  static const defaultModel = 'gpt-4o';
  static const defaultTimeout = Duration(seconds: 45);
  static const openAiChatUrl = 'https://api.openai.com/v1/chat/completions';
  static const localDevProxyUrl = 'http://127.0.0.1:8787/v1/ai/complete';

  final AppEnvironment environment;
  final String? proxyUrl;
  final String? openAiKey;
  final String model;
  final Duration timeout;
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

  @visibleForTesting
  static bool loopbackProxyAutoDefaultAllowed({
    TargetPlatform? platform,
    bool? isWeb,
  }) {
    if (isWeb ?? kIsWeb) return true;
    final p = platform ?? defaultTargetPlatform;
    return p != TargetPlatform.android && p != TargetPlatform.iOS;
  }

  @override
  String toString() =>
      'AiRuntimeConfig(env: ${environment.name}, model: $model, '
      'proxy: $usesProxy, clientKey: ${usesClientKey ? 'present' : 'absent'}, '
      'vision: $visionAvailable, timeoutMs: ${timeout.inMilliseconds})';

  factory AiRuntimeConfig.resolve({ApiKeyProvider? keys}) {
    const envDefine = String.fromEnvironment('APP_ENV');
    const proxyDefine = String.fromEnvironment('ORACLY_AI_PROXY_URL');
    const modelDefine = String.fromEnvironment('ORACLY_AI_MODEL');
    const timeoutDefine = String.fromEnvironment('ORACLY_AI_TIMEOUT_SECONDS');
    const visionDefine = String.fromEnvironment('ORACLY_AI_VISION');
    Map<String, String> env = const {};
    try {
      env = dotenv.env;
    } catch (_) {}
    final environment = AppEnvironment.fromString(
      _first([envDefine, env['APP_ENV']]) ??
          (kReleaseMode ? 'production' : null),
    );
    final key = environment.isDevelopment && !kReleaseMode
        ? _first([keys?.openAiKey, env['OPENAI_API_KEY']])
        : null;
    final visionRaw =
        (_first([visionDefine, env['ORACLY_AI_VISION']]) ?? 'true')
            .toLowerCase();
    var proxyUrl = _first([proxyDefine, env['ORACLY_AI_PROXY_URL']]);
    if (proxyUrl == null &&
        environment.isDevelopment &&
        !kReleaseMode &&
        !const bool.fromEnvironment('FLUTTER_TEST') &&
        loopbackProxyAutoDefaultAllowed()) {
      proxyUrl = localDevProxyUrl;
    }
    return AiRuntimeConfig(
      environment: environment,
      proxyUrl: AiProxyUrlPolicy.sanitize(
        raw: proxyUrl,
        isDevelopment: environment.isDevelopment,
        releaseLocked: kReleaseMode,
      ),
      openAiKey: key,
      model: _first([modelDefine, env['ORACLY_AI_MODEL']]) ?? defaultModel,
      timeout: Duration(
        seconds: (int.tryParse(
                  _first([timeoutDefine, env['ORACLY_AI_TIMEOUT_SECONDS']]) ??
                      '',
                ) ??
                defaultTimeout.inSeconds)
            .clamp(15, 90),
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