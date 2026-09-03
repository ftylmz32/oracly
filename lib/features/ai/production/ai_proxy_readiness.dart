/// Ensures proxy AI prerequisites before the first network hop.
library;

import 'package:firebase_core/firebase_core.dart';

import '../../../core/auth/anonymous_auth_bootstrap.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/firebase/firebase_app_check_bootstrap.dart';
import '../../../core/auth/firebase/firebase_auth_bootstrap.dart';
import '../../../core/auth/firebase/firebase_auth_gateway.dart';
import '../../../core/auth/firebase/live_firebase_auth_gateway.dart';
import '../../../core/auth/mock_auth_service.dart';
import 'ai_failure.dart';
import 'ai_runtime_config.dart';
import 'transport/ai_token_reader.dart';
import 'transport/proxy_ai_headers.dart';

abstract final class AiProxyReadiness {
  AiProxyReadiness._();

  static const _sessionWait = Duration(seconds: 8);
  static const _tokenRetryDelay = Duration(milliseconds: 350);

  /// Returns a typed failure when proxy prerequisites are not satisfiable.
  static Future<AiFailure?> ensure({
    required AiRuntimeConfig config,
    AuthService? auth,
    AiTokenReader? accessToken,
    AiTokenReader? appCheckToken,
    FirebaseAuthGateway? liveGateway,
  }) async {
    if (!config.usesProxy) return null;

    if (!FirebaseAuthBootstrap.isReady) {
      await FirebaseAuthBootstrap.tryInitialize();
    }

    await _ensureAnonymousSession(auth: auth, liveGateway: liveGateway);

    final userToken = await _resolveUserToken(
      config: config,
      accessToken: accessToken,
      liveGateway: liveGateway,
    );
    if (userToken == null || userToken.isEmpty) {
      if (!FirebaseAuthBootstrap.isReady) return AiFailure.authPending();
      final gateway = _resolveLiveGateway(liveGateway);
      if (gateway?.currentUser != null) return AiFailure.authPending();
      return AiFailure.unauthorized();
    }

    if (!ProxyAiHeaders.requiresAppCheck(config)) return null;

    if (!FirebaseAppCheckBootstrap.isActivated) {
      await FirebaseAppCheckBootstrap.tryActivate(
        environment: config.environment,
        releaseLocked: config.simulateReleaseBuild,
      );
    }

    final attestation = await _resolveToken(appCheckToken);
    if (attestation == null || attestation.isEmpty) {
      return AiFailure.appCheck();
    }
    return null;
  }

  static Future<void> _ensureAnonymousSession({
    AuthService? auth,
    FirebaseAuthGateway? liveGateway,
  }) async {
    if (auth != null && auth.isConfigured && auth is! MockAuthService) {
      await AnonymousAuthBootstrap.ensure(auth, timeout: _sessionWait);
    }
    // Always fall through: ensure may time out while Firebase is already ready.
    final gateway = _resolveLiveGateway(liveGateway);
    if (gateway == null || gateway.currentUser != null) return;
    if (auth is MockAuthService) return;
    try {
      await gateway.signInAnonymously();
    } catch (_) {}
  }

  static Future<String?> _resolveUserToken({
    required AiRuntimeConfig config,
    AiTokenReader? accessToken,
    FirebaseAuthGateway? liveGateway,
  }) async {
    final fromReader = await _resolveToken(accessToken);
    if (fromReader != null &&
        fromReader.isNotEmpty &&
        ProxyAiHeaders.maySendUserToken(config, fromReader)) {
      return fromReader;
    }
    final gateway = _resolveLiveGateway(liveGateway);
    if (gateway == null) return null;
    final live = (await gateway.currentIdToken(forceRefresh: false))?.trim();
    if (live != null &&
        live.isNotEmpty &&
        ProxyAiHeaders.maySendUserToken(config, live)) {
      return live;
    }
    await Future<void>.delayed(_tokenRetryDelay);
    final refreshed =
        (await gateway.currentIdToken(forceRefresh: true))?.trim();
    if (refreshed != null &&
        refreshed.isNotEmpty &&
        ProxyAiHeaders.maySendUserToken(config, refreshed)) {
      return refreshed;
    }
    return null;
  }

  static FirebaseAuthGateway? _resolveLiveGateway(
    FirebaseAuthGateway? injected,
  ) {
    if (injected != null) return injected;
    if (!FirebaseAuthBootstrap.isReady) return null;
    if (Firebase.apps.isEmpty) return null;
    return LiveFirebaseAuthGateway();
  }

  static Future<String?> _resolveToken(AiTokenReader? reader) async {
    if (reader == null) return null;
    final first = (await reader(forceRefresh: false))?.trim();
    if (first != null && first.isNotEmpty) return first;
    await Future<void>.delayed(_tokenRetryDelay);
    return (await reader(forceRefresh: true))?.trim();
  }
}
