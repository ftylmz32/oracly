/// AiProxyUrlPolicy — loopback / LAN / HTTPS rules for locked builds.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_proxy_url_policy.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';

void main() {
  group('AiProxyUrlPolicy', () {
    test('development may keep loopback and LAN http', () {
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://127.0.0.1:8787/v1/ai/complete',
          isDevelopment: true,
          releaseLocked: false,
        ),
        'http://127.0.0.1:8787/v1/ai/complete',
      );
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://192.168.1.20:8787/v1/ai/complete',
          isDevelopment: true,
          releaseLocked: false,
        ),
        'http://192.168.1.20:8787/v1/ai/complete',
      );
    });

    test('production rejects loopback, LAN, and plain http', () {
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://127.0.0.1:8787/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: false,
        ),
        isNull,
      );
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://localhost:8787/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: false,
        ),
        isNull,
      );
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://192.168.1.20:8787/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: false,
        ),
        isNull,
      );
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://10.0.0.8:8787/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: false,
        ),
        isNull,
      );
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://api.example.com/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: false,
        ),
        isNull,
      );
    });

    test('production accepts public HTTPS only', () {
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'https://api.example.com/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: false,
        ),
        'https://api.example.com/v1/ai/complete',
      );
    });

    test('releaseLocked rejects developer networking even in development env',
        () {
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://127.0.0.1:8787/v1/ai/complete',
          isDevelopment: true,
          releaseLocked: true,
        ),
        isNull,
      );
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: 'http://192.168.1.20:8787/v1/ai/complete',
          isDevelopment: true,
          releaseLocked: true,
        ),
        isNull,
      );
    });

    test('empty and whitespace become null', () {
      expect(
        AiProxyUrlPolicy.sanitize(
          raw: '   ',
          isDevelopment: false,
          releaseLocked: false,
        ),
        isNull,
      );
    });
  });

  group('AiRuntimeConfig production URL', () {
    test('production LAN or loopback proxy is treated as unconfigured', () {
      const lan = AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: 'http://192.168.1.20:8787/v1/ai/complete',
      );
      expect(lan.resolvedProxyUrl, isNull);
      expect(lan.usesProxy, isFalse);
      expect(lan.isConfigured, isFalse);

      const loop = AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      );
      expect(loop.resolvedProxyUrl, isNull);
      expect(loop.isConfigured, isFalse);
    });

    test('staging rejects http LAN the same way', () {
      const cfg = AiRuntimeConfig(
        environment: AppEnvironment.staging,
        proxyUrl: 'http://10.0.0.5:8787/v1/ai/complete',
      );
      expect(cfg.resolvedProxyUrl, isNull);
      expect(cfg.isConfigured, isFalse);
    });
  });
}
