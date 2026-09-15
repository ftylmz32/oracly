/// R6 — TLS / certificate-pinning truthfulness contract (platform TLS only).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_config.dart';
import 'package:oracly_new/core/config/environment_config.dart';
import 'package:oracly_new/core/config/release_endpoint_policy.dart';
import 'package:oracly_new/core/network/api_client.dart';
import 'package:oracly_new/core/security/certificate_pinning.dart';

void main() {
  tearDown(AppConfig.reset);

  group('PLATFORM_TLS_ONLY production contract', () {
    test('production API base is HTTPS and not loopback', () {
      final cfg = EnvironmentConfig.fromEnv(const {'APP_ENV': 'production'});
      expect(cfg.apiBaseUrl, startsWith('https://'));
      expect(ReleaseEndpointPolicy.isHttpsUrl(cfg.apiBaseUrl), isTrue);
      expect(ReleaseEndpointPolicy.isLoopbackUrl(cfg.apiBaseUrl), isFalse);
    });

    test('HTTP production API_BASE_URL is rejected', () {
      final cfg = EnvironmentConfig.fromEnv(const {
        'APP_ENV': 'production',
        'API_BASE_URL': 'http://api.oracly.app',
      });
      expect(cfg.apiBaseUrl, 'https://api.oracly.app');
    });

    test('localhost production override is rejected', () {
      final cfg = EnvironmentConfig.fromEnv(const {
        'APP_ENV': 'production',
        'API_BASE_URL': 'http://localhost:8080',
      });
      expect(cfg.apiBaseUrl, 'https://api.oracly.app');
    });

    test('127.0.0.1 production override is rejected', () {
      final cfg = EnvironmentConfig.fromEnv(const {
        'APP_ENV': 'production',
        'API_BASE_URL': 'http://127.0.0.1:8787',
      });
      expect(cfg.apiBaseUrl, 'https://api.oracly.app');
    });

    test('placeholder production override is locked to HTTPS fallback', () {
      final cfg = EnvironmentConfig.fromEnv(const {
        'APP_ENV': 'production',
        'API_BASE_URL': 'https://REPLACE_WITH_PRODUCTION_HOST',
      });
      expect(cfg.apiBaseUrl, startsWith('https://'));
      expect(
        ReleaseEndpointPolicy.sanitize(
          raw: 'https://REPLACE_WITH_PRODUCTION_HOST/v1/ai/complete',
          isDevelopment: false,
          releaseLocked: true,
        ),
        isNull,
      );
    });

    test('ENABLE_CERT_PINNING cannot enable fake production pinning', () async {
      final cfg = EnvironmentConfig.fromEnv(const {
        'APP_ENV': 'production',
        'ENABLE_CERT_PINNING': 'true',
      });
      expect(cfg.enableCertificatePinning, isFalse);
      await AppConfig.initialize(cfg);
      const pins = EnvironmentCertificatePinning();
      expect(pins.isEnabled, isFalse);
      expect(pins.pinnedCertificates, isEmpty);
      expect(CertificatePinningReadiness.reportsActiveEnforcement(pins), isFalse);
      expect(CertificatePinningReadiness.reportsActiveEnforcement(), isFalse);
    });

    test('no placeholder SPKI pins remain in pinning config', () {
      const source = EnvironmentCertificatePinning();
      expect(source.pinnedCertificates, isEmpty);
      final file = File('lib/core/security/certificate_pinning.dart')
          .readAsStringSync();
      expect(file.contains('sha256/AAAA'), isFalse);
      expect(file.contains('sha256/BBBB'), isFalse);
      expect(file.contains('NoOpCertificatePinValidator'), isFalse);
    });
  });

  group('ApiClient transport', () {
    test('uses injectable http.Client without trust-all callbacks', () async {
      final client = ApiClient(
        client: MockClient((request) async {
          return http.Response('{"ok":true}', 200);
        }),
      );
      final result = await client.get<Map<String, dynamic>>(
        'https://api.oracly.app/v1/health',
        parser: (json) => json as Map<String, dynamic>,
      );
      expect(result.isSuccess, isTrue);
      client.dispose();
    });

    test('ApiClient source has no certificate trust bypass', () {
      final source = File('lib/core/network/api_client.dart').readAsStringSync();
      expect(source.contains('badCertificateCallback'), isFalse);
      expect(source.contains('HttpOverrides'), isFalse);
      expect(source.contains('withTrustedRoots: false'), isFalse);
      expect(source.contains('http.Client()'), isTrue);
    });
  });

  group('Android / iOS release network policy', () {
    test('Android main/release manifest does not allow cleartext', () {
      final main = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(main.contains('usesCleartextTraffic="true"'), isFalse);
      expect(main.contains('networkSecurityConfig'), isFalse);
      final debug = File('android/app/src/debug/AndroidManifest.xml')
          .readAsStringSync();
      expect(debug.contains('usesCleartextTraffic="true"'), isTrue);
    });

    test('iOS Info.plist does not enable arbitrary loads', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist.contains('NSAllowsArbitraryLoads'), isFalse);
      expect(plist.contains('NSExceptionAllowsInsecureHTTPLoads'), isFalse);
    });
  });

  group('TLS bypass source scan (production lib)', () {
    test('no trust-all / HttpOverrides in production lib sources', () {
      final hits = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        if (text.contains('badCertificateCallback') ||
            text.contains('HttpOverrides') ||
            text.contains('withTrustedRoots: false')) {
          hits.add(entity.path);
        }
      }
      expect(hits, isEmpty, reason: hits.join(', '));
    });
  });
}
