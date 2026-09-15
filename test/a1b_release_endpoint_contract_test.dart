/// A1B release endpoint contract: production is explicit, HTTPS-only, and
/// cannot inherit an implicit development loopback fallback.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/environment_config.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';
import 'package:oracly_new/core/config/oracly_runtime_keys.dart';

void main() {
  setUp(() => OraclyRuntimeConfig.testEnv = null);
  tearDown(() => OraclyRuntimeConfig.testEnv = null);

  test('production defines resolve only to the accepted R5 HTTPS routes', () {
    final values =
        jsonDecode(File('tool/dart_defines.production.json').readAsStringSync())
            as Map<String, dynamic>;
    OraclyRuntimeConfig.testEnv = values.map(
      (key, value) => MapEntry(key, '$value'),
    );

    final config = OraclyRuntimeConfig.resolve(releaseLocked: true);
    expect(config.environment.name, 'production');
    expect(
      config.aiProxyUrl,
      'https://oracly-api-uya7zqzwra-ew.a.run.app/v1/ai/complete',
    );
    expect(
      config.billingVerifyUrl,
      'https://oracly-api-uya7zqzwra-ew.a.run.app/v1/billing/verify',
    );
    expect(config.isReleaseConfigComplete, isTrue);
  });

  test('missing production endpoints fail closed', () {
    OraclyRuntimeConfig.testEnv = {OraclyRuntimeKeys.appEnv: 'production'};
    final config = OraclyRuntimeConfig.resolve(releaseLocked: true);
    expect(config.aiProxyUrl, isNull);
    expect(config.billingVerifyUrl, isNull);
    expect(config.isReleaseConfigComplete, isFalse);
  });

  test(
    'malformed, non-HTTPS, and loopback production endpoints fail closed',
    () {
      for (final endpoint in <String>[
        'not a URL',
        'http://api.oracly.app/v1/ai/complete',
        'http://localhost:8080/v1/ai/complete',
      ]) {
        OraclyRuntimeConfig.testEnv = {
          OraclyRuntimeKeys.appEnv: 'production',
          OraclyRuntimeKeys.aiProxyUrl: endpoint,
          OraclyRuntimeKeys.billingVerifyUrl: endpoint,
        };
        final config = OraclyRuntimeConfig.resolve(releaseLocked: true);
        expect(config.aiProxyUrl, isNull, reason: endpoint);
        expect(config.billingVerifyUrl, isNull, reason: endpoint);
      }
    },
  );

  test('development loopback requires explicit configuration', () {
    final implicit = EnvironmentConfig.fromEnv(const {
      'APP_ENV': 'development',
    });
    final explicit = EnvironmentConfig.fromEnv(const {
      'APP_ENV': 'development',
      'DEV_API_BASE_URL': 'http://localhost:8080',
    });
    expect(implicit.apiBaseUrl, isEmpty);
    expect(explicit.apiBaseUrl, 'http://localhost:8080');
  });
}
