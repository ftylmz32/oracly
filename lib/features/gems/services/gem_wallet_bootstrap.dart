/// Ensures auth + App Check before wallet network calls.
library;

import 'package:flutter/foundation.dart';

import '../../../core/auth/anonymous_auth_bootstrap.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/auth/firebase/firebase_app_check_bootstrap.dart';
import '../../../core/auth/firebase/firebase_auth_bootstrap.dart';
import '../../../core/auth/firebase/firebase_auth_gateway.dart';
import '../../ai/production/ai_proxy_readiness.dart';
import '../../ai/production/ai_runtime_config.dart';
import '../../ai/production/transport/ai_token_reader.dart';

/// Cold-start wallet traffic must not race ahead of anonymous auth / App Check.
abstract final class GemWalletBootstrap {
  GemWalletBootstrap._();

  static Future<bool> ensureReady({
    required AiRuntimeConfig config,
    required AuthService auth,
    AiTokenReader? accessToken,
    AiTokenReader? appCheckToken,
    FirebaseAuthGateway? liveGateway,
  }) async {
    if (!config.usesProxy) {
      print('[GemWallet] proxy not configured — cannot hydrate');
      return false;
    }
    if (!FirebaseAuthBootstrap.isReady) {
      await FirebaseAuthBootstrap.tryInitialize();
    }
    await FirebaseAppCheckBootstrap.tryActivate(
      environment: config.environment,
      releaseLocked: config.simulateReleaseBuild || kReleaseMode,
    );
    await AnonymousAuthBootstrap.ensure(auth);
    final failure = await AiProxyReadiness.ensure(
      config: config,
      auth: auth,
      accessToken: accessToken,
      appCheckToken: appCheckToken,
      liveGateway: liveGateway,
    );
    if (failure != null) {
      print('[GemWallet] transport not ready: $failure');
      return false;
    }
    print('[GemWallet] transport ready');
    return true;
  }
}
