/// Canonical release runtime config — mandatory keys, HTTPS, no secrets.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';
import 'package:oracly_new/core/config/oracly_runtime_keys.dart';
import 'package:oracly_new/core/config/release_endpoint_policy.dart';
import 'package:oracly_new/features/premium/services/premium_billing_config.dart';

void main() {
  setUp(() => OraclyRuntimeConfig.testEnv = null);
  tearDown(() => OraclyRuntimeConfig.testEnv = null);

  test('catalog classifies mandatory, optional, and debug keys', () {
    expect(
      OraclyRuntimeKeys.mandatoryReleaseNames,
      containsAll([
        OraclyRuntimeKeys.appEnv,
        OraclyRuntimeKeys.aiProxyUrl,
        OraclyRuntimeKeys.billingVerifyUrl,
      ]),
    );
    expect(
      OraclyRuntimeKeys.catalog
          .where((k) => k.name == OraclyRuntimeKeys.devPremium)
          .single
          .classification,
      OraclyRuntimeKeyClass.debugOnly,
    );
    expect(
      OraclyRuntimeKeys.forbiddenClientSecretNames,
      contains(OraclyRuntimeKeys.openAiApiKey),
    );
  });

  test('release rejects empty, localhost, LAN, and plain HTTP', () {
    OraclyRuntimeConfig.testEnv = {
      OraclyRuntimeKeys.appEnv: 'production',
      OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      OraclyRuntimeKeys.billingVerifyUrl: 'http://192.168.1.10/verify',
    };
    final cfg = OraclyRuntimeConfig.resolve(releaseLocked: true);
    expect(cfg.aiProxyUrl, isNull);
    expect(cfg.billingVerifyUrl, isNull);
    expect(
      cfg.missingMandatoryReleaseKeys,
      containsAll([
        OraclyRuntimeKeys.aiProxyUrl,
        OraclyRuntimeKeys.billingVerifyUrl,
      ]),
    );
    expect(cfg.isReleaseConfigComplete, isFalse);
  });

  test('release accepts public HTTPS endpoints', () {
    OraclyRuntimeConfig.testEnv = {
      OraclyRuntimeKeys.appEnv: 'production',
      OraclyRuntimeKeys.aiProxyUrl:
          'https://proxy.oracly.app/v1/ai/complete',
      OraclyRuntimeKeys.billingVerifyUrl:
          'https://proxy.oracly.app/v1/billing/verify',
    };
    final cfg = OraclyRuntimeConfig.resolve(releaseLocked: true);
    expect(cfg.hasAiProxy, isTrue);
    expect(cfg.hasBillingVerify, isTrue);
    expect(cfg.isReleaseConfigComplete, isTrue);
    expect(
      PremiumBillingConfig.resolveVerifyUrl(releaseLocked: true),
      'https://proxy.oracly.app/v1/billing/verify',
    );
  });

  test('replace_with placeholders are not valid release endpoints', () {
    expect(
      ReleaseEndpointPolicy.sanitize(
        raw: 'https://REPLACE_WITH_PRODUCTION_HOST/v1/ai/complete',
        isDevelopment: false,
        releaseLocked: true,
      ),
      isNull,
    );
  });

  test('development may keep loopback for local work', () {
    OraclyRuntimeConfig.testEnv = {
      OraclyRuntimeKeys.appEnv: 'development',
      OraclyRuntimeKeys.aiProxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
      OraclyRuntimeKeys.billingVerifyUrl: 'http://127.0.0.1:8787/v1/billing/verify',
    };
    final cfg = OraclyRuntimeConfig.resolve(releaseLocked: false);
    expect(cfg.aiProxyUrl, contains('127.0.0.1'));
    expect(cfg.billingVerifyUrl, contains('127.0.0.1'));
  });

  test('production dart-define example is public-only and documents billing', () {
    final example = File('tool/dart_defines.production.example.json');
    final map = jsonDecode(example.readAsStringSync()) as Map<String, dynamic>;
    expect(map['APP_ENV'], 'production');
    expect(map.containsKey('ORACLY_AI_PROXY_URL'), isTrue);
    expect(map.containsKey('ORACLY_BILLING_VERIFY_URL'), isTrue);
    expect(map.containsKey('OPENAI_API_KEY'), isFalse);
    for (final key in map.keys) {
      expect(key.toUpperCase(), isNot(contains('OPENAI')));
      expect(key.toUpperCase(), isNot(contains('SECRET')));
      expect(key.toUpperCase(), isNot(contains('PRIVATE')));
    }
    final proxy = map['ORACLY_AI_PROXY_URL'] as String;
    expect(proxy.startsWith('https://'), isTrue);
    expect(
      ReleaseEndpointPolicy.sanitize(
        raw: proxy,
        isDevelopment: false,
        releaseLocked: true,
      ),
      isNull,
      reason: 'example placeholders must not pass release sanitization',
    );
  });
}