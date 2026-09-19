/// Production reading-operation client. No local gem authority.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/firebase/firebase_app_check_token.dart';
import '../../../core/providers/backend_providers.dart';
import '../../ai/production/ai_proxy_readiness.dart';
import '../../ai/production/oracly_ai_providers.dart';
import '../../ai/production/transport/ai_operation.dart';
import '../../ai/production/transport/ai_proxy_request.dart';
import '../../ai/production/transport/proxy_ai_headers.dart';
import '../../gems/providers/gem_providers.dart';
import '../services/reading_acceleration_client.dart';
import '../services/reading_feature_runner.dart';
import '../services/reading_live_flow.dart';
import '../services/reading_operation_gateway.dart';
import '../services/reading_operation_input_gateway.dart';
import '../services/reading_pending_operation_store.dart';
import '../services/reading_staged_image_gateway.dart';

/// Strips `/v1/ai/complete` from ORACLY_AI_PROXY_URL to get the backend origin.
const _aiCompleteEndpointSuffix = '/v1/ai/complete';

@visibleForTesting
String readingOperationBackendOrigin(String proxyUrl) {
  var root = proxyUrl.endsWith('/')
      ? proxyUrl.substring(0, proxyUrl.length - 1)
      : proxyUrl;
  if (root.endsWith(_aiCompleteEndpointSuffix)) {
    root = root.substring(0, root.length - _aiCompleteEndpointSuffix.length);
  }
  return root;
}

/// Shared authenticated sender for reading + gem wallet transport.
ReadingOperationSender? _buildSender(Ref ref) {
  final config = ref.watch(aiRuntimeConfigProvider);
  final proxy = config.resolvedProxyUrl;
  if (proxy == null || proxy.isEmpty || !config.usesProxy) return null;
  final tokens = ref.watch(tokenManagerProvider);
  final gatewayAuth = ref.watch(firebaseAuthGatewayProvider);
  final auth = ref.watch(authServiceProvider);

  return (String method, String path, Map<String, Object>? body) async {
    // Wallet and reading share this sender — never race ahead of auth/App Check.
    final blocked = await AiProxyReadiness.ensure(
      config: config,
      auth: auth,
      accessToken: ({bool forceRefresh = false}) =>
          tokens.getAccessToken(forceRefresh: forceRefresh),
      appCheckToken: ({bool forceRefresh = false}) =>
          FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
      liveGateway: gatewayAuth,
    );
    if (blocked != null) {
      debugPrint('[ReadingSender] blocked $method $path: $blocked');
      return null;
    }
    final headers = await ProxyAiHeaders.build(
      config: config,
      request: const AiProxyRequest(operation: AiOperation.chat, payload: {}),
      accessToken: ({bool forceRefresh = false}) =>
          tokens.getAccessToken(forceRefresh: forceRefresh),
      appCheckToken: ({bool forceRefresh = false}) =>
          FirebaseAppCheckToken.resolve(forceRefresh: forceRefresh),
      liveGateway: gatewayAuth,
    );
    if (headers == null) return null;
    final root = readingOperationBackendOrigin(proxy);
    final uri = Uri.parse('$root$path');
    final client = http.Client();
    try {
      final response = method == 'GET'
          ? await client.get(uri, headers: headers)
          : await client.post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? const <String, Object>{}),
            );
      final decoded = jsonDecode(response.body);
      return ReadingOperationWire(
        statusCode: response.statusCode,
        json: decoded is Map ? Map<String, dynamic>.from(decoded) : null,
      );
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  };
}

/// Shared authenticated backend sender for server-authoritative wallet APIs.
final readingOperationSenderProvider = Provider<ReadingOperationSender?>((ref) {
  return _buildSender(ref);
});

final readingFeatureRunnerProvider = Provider<ReadingFeatureRunner?>((ref) {
  final send = ref.watch(readingOperationSenderProvider);
  if (send == null) return null;
  final operations = ReadingOperationGateway(send: send);
  return ReadingFeatureRunner(
    serverOwnedCompletion: true,
    stagedImages: ReadingStagedImageGateway(send),
    inputs: ReadingOperationInputGateway(send: send),
    flow: ReadingLiveFlow(
      operations: operations,
      acceleration: ReadingAccelerationClient(
        send: send,
        onAuthoritativeBalance: (balance) => ref
            .read(gemWalletProvider)
            .acceptAuthoritativeBalance(balance),
      ),
      send: send,
    ),
  );
});

final readingOperationInputGatewayProvider =
    Provider<ReadingOperationInputGateway?>((ref) {
      final send = ref.watch(readingOperationSenderProvider);
      if (send == null) return null;
      return ReadingOperationInputGateway(send: send);
    });

/// Shared by Coffee/Palm controllers to persist just enough identity
/// (never image bytes) about an in-flight `waiting` operation so
/// recovery after an app restart/controller disposal can find and
/// resume the SAME staged operation — see ReadingPendingOperationStore.
final readingPendingOperationStoreProvider =
    Provider<ReadingPendingOperationStore>((ref) {
      return ReadingPendingOperationStore(ref.watch(localStorageProvider));
    });
