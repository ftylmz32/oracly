/// Builds sanitized headers for [ProxyAiTransport].
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/auth/firebase/firebase_app_check_policy.dart';
import '../../../../core/auth/firebase/firebase_auth_bootstrap.dart';
import '../../../../core/auth/firebase/firebase_auth_gateway.dart';
import '../../../../core/auth/firebase/live_firebase_auth_gateway.dart';
import '../ai_runtime_config.dart';
import 'ai_proxy_request.dart';
import 'ai_token_reader.dart';

abstract final class ProxyAiHeaders {
  ProxyAiHeaders._();

  static const appCheckHeader = 'X-Firebase-AppCheck';

  static bool requiresAppCheck(AiRuntimeConfig config) {
    return FirebaseAppCheckPolicy.requiresToken(
      environment: config.environment,
      usesProxy: config.usesProxy,
      releaseLocked: config.simulateReleaseBuild || kReleaseMode,
    );
  }

  static Future<Map<String, String>?> build({
    required AiRuntimeConfig config,
    required AiProxyRequest request,
    AiTokenReader? accessToken,
    AiTokenReader? appCheckToken,
    FirebaseAuthGateway? liveGateway,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _resolveUserToken(
      config: config,
      accessToken: accessToken,
      liveGateway: liveGateway,
    );
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final appCheck = (await appCheckToken?.call(forceRefresh: false))?.trim();
    final required = requiresAppCheck(config);
    if (required) {
      if (appCheck == null || appCheck.isEmpty) return null;
      headers[appCheckHeader] = appCheck;
    } else if (appCheck != null && appCheck.isNotEmpty) {
      headers[appCheckHeader] = appCheck;
    }
    final idem = request.idempotencyKey?.trim();
    if (idem != null && idem.isNotEmpty) {
      headers['Idempotency-Key'] =
          idem.length > 128 ? idem.substring(0, 128) : idem;
    }
    return headers;
  }

  static Future<String?> _resolveUserToken({
    required AiRuntimeConfig config,
    AiTokenReader? accessToken,
    FirebaseAuthGateway? liveGateway,
  }) async {
    final fromReader = (await accessToken?.call(forceRefresh: false))?.trim();
    if (fromReader != null &&
        fromReader.isNotEmpty &&
        maySendUserToken(config, fromReader)) {
      return fromReader;
    }
    final gateway = liveGateway ??
        (FirebaseAuthBootstrap.isReady && Firebase.apps.isNotEmpty
            ? LiveFirebaseAuthGateway()
            : null);
    if (gateway == null) return null;
    final live = (await gateway.currentIdToken(forceRefresh: false))?.trim();
    if (live != null && live.isNotEmpty && maySendUserToken(config, live)) {
      return live;
    }
    final refreshed =
        (await gateway.currentIdToken(forceRefresh: true))?.trim();
    if (refreshed != null &&
        refreshed.isNotEmpty &&
        maySendUserToken(config, refreshed)) {
      return refreshed;
    }
    return null;
  }

  /// Never send OpenAI keys or MockAuthService tokens in production.
  static bool maySendUserToken(AiRuntimeConfig config, String token) {
    if (token.startsWith('sk-')) return false;
    final locked =
        !config.environment.isDevelopment ||
        kReleaseMode ||
        config.simulateReleaseBuild;
    if (locked && token.startsWith('mock_')) return false;
    return true;
  }
}
