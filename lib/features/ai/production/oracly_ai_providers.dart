/// Riverpod wiring — proxy in production, direct OpenAI only in explicit DEV.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/firebase/firebase_app_check_token.dart';
import '../../../core/providers/backend_providers.dart'
    show apiKeyProvider, tokenManagerProvider;
import 'ai_runtime_config.dart';
import 'openai/openai_oracly_ai_service.dart';
import 'oracly_ai_service.dart';
import 'transport/ai_transport.dart';
import 'transport/ai_transport_selection.dart';
import 'unconfigured_oracly_ai_service.dart';

final aiRuntimeConfigProvider = Provider<AiRuntimeConfig>((ref) {
  return AiRuntimeConfig.resolve(keys: ref.watch(apiKeyProvider));
});

final aiTransportProvider = Provider<AiTransport?>((ref) {
  final config = ref.watch(aiRuntimeConfigProvider);
  return AiTransportSelection.create(
    config,
    accessToken: () => ref.read(tokenManagerProvider).getAccessToken(),
    appCheckToken: () => FirebaseAppCheckToken.resolve(),
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
