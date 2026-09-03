/// Shared proxy readiness — auth + App Check before non-Tarot AI hops.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_bootstrap.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_proxy_readiness.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';

const _proxy = 'https://api.oracly.app/v1/ai/complete';
const _prod = AiRuntimeConfig(
  environment: AppEnvironment.production,
  proxyUrl: _proxy,
);

void main() {
  setUp(FirebaseAuthBootstrap.reset);
  tearDown(FirebaseAuthBootstrap.reset);

  test('missing auth token while Firebase is not ready is pending', () async {
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      auth: MockAuthService(),
      accessToken: ({bool forceRefresh = false}) async => null,
      appCheckToken: ({bool forceRefresh = false}) async => 'app-check',
    );
    expect(failure?.kind, AiFailureKind.authPending);
  });

  test('missing App Check is appCheck, not unauthorized', () async {
    FirebaseAuthBootstrap.debugSetReady(true);
    final failure = await AiProxyReadiness.ensure(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => 'firebase-token',
      appCheckToken: ({bool forceRefresh = false}) async => null,
    );
    expect(failure?.kind, AiFailureKind.appCheck);
  });

  test('retries access token with forceRefresh', () async {
    var calls = 0;
    final failure = await AiProxyReadiness.ensure(
      config: const AiRuntimeConfig(
        environment: AppEnvironment.development,
        proxyUrl: _proxy,
      ),
      accessToken: ({bool forceRefresh = false}) async {
        calls++;
        if (forceRefresh) return 'fresh-token';
        return null;
      },
    );
    expect(failure, isNull);
    expect(calls, 2);
  });
}
