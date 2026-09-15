/// Regression coverage for the shared AI runtime config resolution chain.
///
/// A prior change made `AiRuntimeConfig.resolve()` discard an explicitly
/// configured `ORACLY_AI_PROXY_URL` whenever `APP_ENV` was not literally
/// `"local"` — silently booting `APP_ENV=development` (the documented,
/// historically-working local dev value) into `configured=false` even with
/// a valid proxy URL present. These tests pin the corrected behavior:
/// an explicit proxy URL is honored under plain `development`, `local`
/// only adds a zero-config loopback auto-guess, release stays fail-closed
/// against localhost regardless, and every AI feature reads the same
/// resolved config through one shared provider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';
import 'package:oracly_new/core/config/oracly_runtime_keys.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/palm/providers/palm_providers.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_providers.dart';

void main() {
  setUp(() => OraclyRuntimeConfig.testEnv = null);
  tearDown(() => OraclyRuntimeConfig.testEnv = null);

  group('AiRuntimeConfig.resolve — development', () {
    test(
        'an explicit ORACLY_AI_PROXY_URL is honored under plain '
        'APP_ENV=development (the documented local-dev value)', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'development',
        OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      };
      final config = AiRuntimeConfig.resolve();
      expect(config.environment, AppEnvironment.development);
      expect(config.resolvedProxyUrl, 'http://127.0.0.1:8787/v1/ai/complete');
      expect(config.usesProxy, isTrue);
      expect(config.isConfigured, isTrue);
    });

    test('missing config fails honestly (no silent local fallback)', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'development',
      };
      final config = AiRuntimeConfig.resolve();
      expect(config.resolvedProxyUrl, isNull);
      expect(config.usesProxy, isFalse);
      expect(config.isConfigured, isFalse);
    });

    test(
        'APP_ENV=local with no explicit proxy URL auto-guesses a loopback '
        'URL (zero-config convenience, unrelated to the regression)', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'local',
      };
      final config = AiRuntimeConfig.resolve();
      expect(config.usesProxy, isTrue);
      expect(config.resolvedProxyUrl, isNotNull);
    });

    test('APP_ENV=local still honors an explicit proxy URL over the auto-guess', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'local',
        OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:9999/v1/ai/complete',
      };
      final config = AiRuntimeConfig.resolve();
      expect(config.resolvedProxyUrl, 'http://127.0.0.1:9999/v1/ai/complete');
    });

    test('vision flag resolves correctly (default true, explicit false honored)', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'development',
        OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      };
      expect(AiRuntimeConfig.resolve().visionAvailable, isTrue);

      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'development',
        OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
        OraclyRuntimeKeys.aiVision: 'false',
      };
      final config = AiRuntimeConfig.resolve();
      expect(config.isConfigured, isTrue);
      expect(config.visionAvailable, isFalse);
    });
  });

  group('AiRuntimeConfig — release stays fail-closed against localhost', () {
    test('a loopback proxy URL is rejected once release-locked', () {
      const config = AiRuntimeConfig(
        environment: AppEnvironment.development,
        proxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
        simulateReleaseBuild: true,
      );
      expect(config.resolvedProxyUrl, isNull);
      expect(config.usesProxy, isFalse);
      expect(config.isConfigured, isFalse);
    });

    test('a real HTTPS proxy URL still resolves once release-locked', () {
      const config = AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: 'https://api.oracly.app/v1/ai/complete',
        simulateReleaseBuild: true,
      );
      expect(config.resolvedProxyUrl, 'https://api.oracly.app/v1/ai/complete');
      expect(config.usesProxy, isTrue);
    });

    test('a client OpenAI key is never allowed once release-locked', () {
      const config = AiRuntimeConfig(
        environment: AppEnvironment.development,
        openAiKey: 'sk-test-should-never-be-used',
        simulateReleaseBuild: true,
      );
      expect(config.allowsClientOpenAiKey, isFalse);
      expect(config.usesClientKey, isFalse);
    });
  });

  group('shared config — every AI feature reads the same resolved instance', () {
    test('aiRuntimeConfigProvider is a single cached instance across readers', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'development',
        OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      };
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final first = container.read(aiRuntimeConfigProvider);
      final second = container.read(aiRuntimeConfigProvider);
      expect(identical(first, second), isTrue);
      expect(first.isConfigured, isTrue);
    });

    test(
        'coffee/palm/soulmate port providers do not force a second, '
        'divergent resolution of the runtime config', () {
      OraclyRuntimeConfig.testEnv = {
        OraclyRuntimeKeys.appEnv: 'development',
        OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      };
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWithValue(LocalStorage.ephemeral())],
      );
      addTearDown(container.dispose);
      final shared = container.read(aiRuntimeConfigProvider);
      expect(shared.isConfigured, isTrue);

      // Touching the coffee/palm/soulmate port providers must not force a
      // second, divergent resolution of the runtime config — they all
      // watch the exact same aiRuntimeConfigProvider.
      container.read(coffeeAnalysisProvider);
      container.read(palmAnalysisProvider);
      container.read(soulMateDrawPortProvider);
      expect(identical(container.read(aiRuntimeConfigProvider), shared), isTrue);
    });
  });
}
