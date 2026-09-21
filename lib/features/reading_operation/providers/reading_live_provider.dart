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

  // A sender instance belongs to the first concrete authenticated owner it
  // observes. Provider rebuilds create a new sender for a new owner, while
  // stale controllers keep the old closure — those stale closures must fail
  // closed instead of silently using the new user's live Firebase token.
  String? boundOwnerId =
      gatewayAuth?.currentUser?.uid.trim().isNotEmpty == true
          ? gatewayAuth!.currentUser!.uid.trim()
          : null;

  String? liveOwnerId() {
    final live = gatewayAuth?.currentUser?.uid.trim();
    if (live != null && live.isNotEmpty) return live;
    final serviceOwner = auth.currentUserId?.trim();
    return serviceOwner != null && serviceOwner.isNotEmpty
        ? serviceOwner
        : null;
  }

  bool bindOrMatchesOwner() {
    final live = liveOwnerId();
    if (live == null) return boundOwnerId == null;
    final bound = boundOwnerId;
    if (bound == null) {
      boundOwnerId = live;
      return true;
    }
    return bound == live;
  }

  return (String method, String path, Map<String, Object>? body) async {
    if (!bindOrMatchesOwner()) {
      debugPrint('[ReadingSender] blocked stale owner $method $path');
      return null;
    }
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
    if (!bindOrMatchesOwner()) {
      debugPrint('[ReadingSender] blocked owner change $method $path');
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
    // Auth can change while token/App Check headers are being resolved.
    // Re-check immediately before network I/O so a stale sender never emits
    // a request carrying another owner's freshly-issued token.
    if (!bindOrMatchesOwner()) {
      debugPrint('[ReadingSender] blocked post-header owner change $method $path');
      return null;
    }
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
