/// Phase E2 — staging dart-defines are non-secret and placeholder-safe.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/oracly_runtime_keys.dart';
import 'package:oracly_new/core/config/release_endpoint_policy.dart';

void main() {
  test('staging example has no OpenAI key and keeps REPLACE placeholders', () {
    final file = File('tool/dart_defines.staging.example.json');
    expect(file.existsSync(), isTrue);
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(map['APP_ENV'], 'staging');
    expect(map.containsKey('OPENAI_API_KEY'), isFalse);
    expect(map['ORACLY_AI_IMAGE_TIMEOUT_SECONDS'], '120');
    final proxy = map['ORACLY_AI_PROXY_URL'] as String;
    expect(proxy, contains('REPLACE_WITH_CLOUD_RUN_HOST'));
    expect(
      ReleaseEndpointPolicy.sanitize(
        raw: proxy,
        isDevelopment: false,
        releaseLocked: true,
      ),
      isNull,
      reason: 'placeholders must fail release sanitization',
    );
  });

  test('production example still rejects REPLACE_WITH placeholders', () {
    final file = File('tool/dart_defines.production.example.json');
    final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(map.containsKey('OPENAI_API_KEY'), isFalse);
    expect(map['ORACLY_AI_IMAGE_TIMEOUT_SECONDS'], '120');
    final proxy = map[OraclyRuntimeKeys.aiProxyUrl] as String;
    expect(
      ReleaseEndpointPolicy.sanitize(
        raw: proxy,
        isDevelopment: false,
        releaseLocked: true,
      ),
      isNull,
    );
  });

  test('image timeout runtime key is catalogued', () {
    expect(
      OraclyRuntimeKeys.catalog.any(
        (k) => k.name == OraclyRuntimeKeys.aiImageTimeoutSeconds,
      ),
      isTrue,
    );
  });
}