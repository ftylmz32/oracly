/// Builds sanitized headers for [ProxyAiTransport].
library;

import 'package:flutter/foundation.dart';

import '../../../../core/auth/firebase/firebase_app_check_policy.dart';
import '../ai_runtime_config.dart';
import 'ai_proxy_request.dart';

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
    required Future<String?> Function()? accessToken,
    required Future<String?> Function()? appCheckToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = (await accessToken?.call())?.trim();
    if (token != null && token.isNotEmpty && maySendUserToken(config, token)) {
      headers['Authorization'] = 'Bearer $token';
    }
    final appCheck = (await appCheckToken?.call())?.trim();
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
