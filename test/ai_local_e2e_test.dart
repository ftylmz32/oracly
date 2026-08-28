/// Local E2E. Proxy path always; real OpenAI only if backend already has a key.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';

import 'support/ai_e2e_probe.dart';
import 'support/test_app_check_token.dart';

bool get _e2e => Platform.environment['ORACLY_E2E'] == '1';

void main() {
  final skip = _e2e ? false : 'Set ORACLY_E2E=1 with local Fastify running';

  setUpAll(() async {
    if (_e2e) await detectE2eProvider();
  });

  test('local backend health is up', () async {
    final res = await http.get(Uri.parse('http://127.0.0.1:8787/health'));
    expect(res.statusCode, 200);
    expect(jsonDecode(res.body), {'status': 'ok'});
    expect(res.body.toLowerCase(), isNot(contains('sk-')));
    expect(res.body.toLowerCase(), isNot(contains('openai')));
  }, skip: skip);

  test('Flutter ProxyAiTransport reaches local Fastify only', () async {
    final probe = AiE2eProbe();
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: e2eProxyUrl,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
      model: 'gpt-4o-mini',
    );
    expect(AiTransportSelection.create(config), isA<ProxyAiTransport>());
    expect(
      AiTransportSelection.create(config),
      isNot(isA<DirectOpenAiTransport>()),
    );
    final result = await OpenAiOraclyAiService(
      config: config,
      transport: ProxyAiTransport(config: config,
      appCheckToken: testAppCheckToken, client: probe),
    ).chat(userMessage: 'Merhaba, bugun sakin bir nefes almak istiyorum.');
    assertProxyOnly(probe, forbidden: 'sk-SHOULD-NOT-BE-SENT');
    expect(jsonDecode(probe.lastBody!)['operation'], 'chat');
    e2eFailIfRateLimited(result.failure?.kind, result.failure?.userMessage);
    if (result.isSuccess) {
      expect(result.value!.text.trim().length, greaterThan(11));
    } else {
      expect(result.failure?.kind, AiFailureKind.noConfiguration);
      expect(result.failure?.userMessage, ResilienceCopy.aiConfigMissing);
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('REAL chat via OpenAI', () async {
    if (e2eProviderBlocker != null) {
      markTestSkipped(e2eProviderBlocker!);
      return;
    }
    final probe = AiE2eProbe();
    final result = await e2eLiveAi(probe).chat(
      userMessage: 'Merhaba, bugun sakin bir nefes almak istiyorum.',
    );
    e2eFailIfRateLimited(result.failure?.kind, result.failure?.userMessage);
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.value!.text.trim().length, greaterThan(11));
    assertProxyOnly(probe, forbidden: 'sk-SHOULD-NOT-BE-SENT');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
