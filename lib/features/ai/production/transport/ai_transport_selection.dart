/// Canonical transport choice — proxy in production, direct OpenAI only in DEV.
library;

import 'package:http/http.dart' as http;

import '../ai_runtime_config.dart';
import 'ai_transport.dart';
import 'direct_openai_transport.dart';
import 'proxy_ai_transport.dart';

abstract final class AiTransportSelection {
  AiTransportSelection._();

  static AiTransport? create(
    AiRuntimeConfig config, {
    Future<String?> Function()? accessToken,
    Future<String?> Function()? appCheckToken,
    http.Client? client,
  }) {
    if (config.usesProxy) {
      return ProxyAiTransport(
        config: config,
        accessToken: accessToken,
        appCheckToken: appCheckToken,
        client: client,
      );
    }
    if (config.usesClientKey) {
      return DirectOpenAiTransport(config: config, client: client);
    }
    return null;
  }
}
