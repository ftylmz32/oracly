/// Riverpod wiring — proxy in production, direct OpenAI only in explicit DEV.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase/firebase_app_check_token.dart';
import '../../../core/providers/backend_providers.dart'
    show
        apiKeyProvider,
        authServiceProvider,
        firebaseAuthGatewayProvider,
        tokenManagerProvider;
import 'ai_runtime_config.dart';
import 'openai/openai_oracly_ai_service.dart';
import 'oracly_ai_service.dart';
import 'transport/ai_transport.dart';
import 'transport/ai_transport_selection.dart';
import 'transport/proxy_ai_transport_log.dart';
import 'unconfigured_oracly_ai_service.dart';

final aiRuntimeConfigProvider = Provider<AiRuntimeConfig>((ref) {
  final config = AiRuntimeConfig.resolve(keys: ref.watch(apiKeyProvider));
  assert(() {
    if (kDebugMode) {
      ProxyAiTransportLog.config(
        configured: config.isConfigured,
        usesProxy: config.usesProxy,
        endpoint: config.resolvedProxyUrl,
        visionAvailable: config.visionAvailable,
      );
    }
    return true;
  }());
  return config;
});

final aiTransportProvider = Provider<AiTransport?>((ref) {
  final config = ref.watch(aiRuntimeConfigProvider);
  final auth = ref.watch(authServiceProvider);
  final tokens = ref.watch(tokenManagerProvider);
  final gateway = ref.watch(firebaseAuthGatewayProvider);
  return AiTransportSelection.create(
    config,
    auth: auth,
    accessToken: ({bool forceRefresh = false}) =>
        tokens.getAccessToken(forceRefresh: forceRefresh),
    appCheckToken: ({bool forceRefresh = false}) =>
        FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
    liveGateway: gateway,
  );
});

final oraclyAiServiceProvider = Provider<OraclyAiService>((ref) {
  final config = ref.watch(aiRuntimeConfigProvider);
  final transport = ref.watch(aiTransportProvider);
  if (transport == null) {
    return UnconfiguredOraclyAiService(
      allowsLocalFallback: config.allowsLocalFallback,
    );
  }
  return OpenAiOraclyAiService(config: config, transport: transport);
});
