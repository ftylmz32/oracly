/// Canonical transport choice — proxy in production, direct OpenAI only in DEV.
library;

import 'package:http/http.dart' as http;

import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/firebase/firebase_auth_gateway.dart';
import '../ai_runtime_config.dart';
import 'ai_token_reader.dart';
import 'ai_transport.dart';
import 'direct_openai_transport.dart';
import 'proxy_ai_transport.dart';

abstract final class AiTransportSelection {
  AiTransportSelection._();

  static AiTransport? create(
    AiRuntimeConfig config, {
    AuthService? auth,
    AiTokenReader? accessToken,
    AiTokenReader? appCheckToken,
    FirebaseAuthGateway? liveGateway,
    http.Client? client,
  }) {
    if (config.usesProxy) {
      return ProxyAiTransport(
        config: config,
        auth: auth,
        accessToken: accessToken,
        appCheckToken: appCheckToken,
        liveGateway: liveGateway,
        client: client,
      );
    }
    if (config.usesClientKey) {
      return DirectOpenAiTransport(config: config, client: client);
    }
    return null;
  }
}
