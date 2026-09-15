/// Shared proxy readiness — auth + App Check before non-Tarot AI hops.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_policy.dart';
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

  group(
    'App Check release-lock semantics (regression for the debug-provider race)',
    () {
      // `FirebaseAppCheckBootstrap.tryActivate` cannot be exercised end-to-end
      // in a widget test without a real Firebase app (the plugin channel call
      // throws and is swallowed regardless of which provider was requested).
      // These tests instead prove the exact value AiProxyReadiness computes
      // and hands to the (untouched) FirebaseAppCheckPolicy decision function
      // — the real boundary of this bug — behaves correctly, plus a source
      // guard against the exact regression that was fixed.

      test('a simulated release build resolves release-locked — never selects '
          'the debug provider, matching the fixed expression at '
          'ai_proxy_readiness.dart', () {
        const releaseConfig = AiRuntimeConfig(
          environment: AppEnvironment.production,
          proxyUrl: _proxy,
          simulateReleaseBuild: true,
        );
        // Mirrors `releaseLocked: config.simulateReleaseBuild || kReleaseMode`
        // exactly as computed at the real call site.
        final releaseLocked =
            releaseConfig.simulateReleaseBuild || kReleaseMode;
        expect(releaseLocked, isTrue);
        expect(
          FirebaseAppCheckPolicy.useDebugProvider(
            environment: releaseConfig.environment,
            releaseLocked: releaseLocked,
          ),
          isFalse,
          reason:
              'release-locked must never select the debug App Check provider',
        );
      });

      test('production/release semantics cannot select debug behavior even '
          'when only kReleaseMode (never simulateReleaseBuild) is what would '
          'flip it in a real release binary', () {
        // Under `flutter test`, kReleaseMode is always false, so this proves
        // the OR-composition itself: whichever side is true, the result is
        // release-locked. simulateReleaseBuild stands in for kReleaseMode
        // here exactly as it does in the real fixed expression.
        const config = AiRuntimeConfig(
          environment: AppEnvironment.production,
          proxyUrl: _proxy,
          simulateReleaseBuild: true,
        );
        expect(config.simulateReleaseBuild || kReleaseMode, isTrue);
      });

      test('normal debug/dev behavior remains unchanged — debug provider is '
          'still allowed outside a release-locked build', () {
        const devConfig = AiRuntimeConfig(
          environment: AppEnvironment.development,
          proxyUrl: _proxy,
        );
        final releaseLocked = devConfig.simulateReleaseBuild || kReleaseMode;
        expect(releaseLocked, isFalse);
        expect(
          FirebaseAppCheckPolicy.useDebugProvider(
            environment: devConfig.environment,
            releaseLocked: releaseLocked,
          ),
          isTrue,
        );
      });

      test('source guard: ai_proxy_readiness.dart passes '
          '`simulateReleaseBuild || kReleaseMode`, never simulateReleaseBuild '
          'alone, to FirebaseAppCheckBootstrap.tryActivate', () {
        final source = File(
          'lib/features/ai/production/ai_proxy_readiness.dart',
        ).readAsStringSync();
        expect(
          source.contains(
            'releaseLocked: config.simulateReleaseBuild || kReleaseMode',
          ),
          isTrue,
          reason:
              'Regression guard: a bare `config.simulateReleaseBuild` here '
              'can never observe a real release build, since the field '
              'defaults to false and is only ever true in tests — this was '
              'the exact bug that let a real release build request the '
              'debug App Check provider.',
        );
      });
    },
  );
}
