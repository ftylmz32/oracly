/// G0 — release runtime config honesty: public HTTPS or fail closed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/oracly_runtime_config.dart';
import 'package:oracly_new/core/config/release_endpoint_policy.dart';

String? _locked(String raw) => ReleaseEndpointPolicy.sanitize(
      raw: raw,
      isDevelopment: false,
      releaseLocked: true,
    );

void main() {
  test('release-locked rejects developer and placeholder endpoints', () {
    for (final raw in [
      '',
      'http://api.oracly.app/v1/ai/complete',
      'https://localhost/v1/ai/complete',
      'https://127.0.0.1:8787/v1/ai/complete',
      'https://10.0.2.2:8787/v1/ai/complete',
      'https://192.168.1.20/v1/ai/complete',
      'https://172.20.0.4/v1/ai/complete',
      'https://oracly.local/v1/ai/complete',
      'https://[::1]/v1/ai/complete',
      'https://REPLACE_WITH_PRODUCTION_HOST/v1/ai/complete',
      'https://<REQUIRED_REAL_HOST>/v1/ai/complete',
      'https://<REQUIRED_PUBLIC_HOST>/privacy',
      'https://placeholder.example/v1/billing/verify',
    ]) {
      expect(_locked(raw), isNull, reason: raw);
    }
  });

  test('release-locked keeps a well-formed public HTTPS endpoint', () {
    const url = 'https://api.oracly.app/v1/ai/complete';
    expect(_locked(url), url);
  });

  test('checked-in release templates never resolve to a usable host', () {
    final example = jsonDecode(
      File('tool/dart_defines.production.example.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final entry in example.entries) {
      final value = '${entry.value}';
      if (!value.startsWith('http')) continue;
      expect(_locked(value), isNull, reason: entry.key);
    }
    final doc = File('docs/RELEASE_RUNTIME_CONFIG.md').readAsStringSync();
    for (final m in RegExp(r'=(https://\S+)').allMatches(doc)) {
      final value = m.group(1)!.replaceAll(RegExp(r'[`\\]+$'), '');
      expect(_locked(value), isNull, reason: value);
    }
  });

  test('release without dart-defines is honestly unconfigured', () {
    final config = OraclyRuntimeConfig.resolve(releaseLocked: true);
    expect(config.releaseLocked, isTrue);
    expect(config.hasAiProxy, isFalse);
    expect(config.hasBillingVerify, isFalse);
    expect(config.privacyPolicyUrl, isNull);
  });

  test('docs keep generic Flutter model distinct from the Dream writer', () {
    final doc = File('docs/RELEASE_RUNTIME_CONFIG.md').readAsStringSync();
    expect(doc, contains('ORACLY_AI_MODEL'));
    expect(doc, contains('gpt-6-astra'));
    expect(doc, contains('4c3-astra'));
  });
}
