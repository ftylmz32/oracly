/// Auth/deployment prep — Flutter still has no real IdP.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'support/test_app_check_token.dart';

const _proxy = 'https://api.oracly.app/v1/ai/complete';

void main() {
  test('production never falls back to direct OpenAI', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-SHOULD-NOT-BE-USED',
    );
    expect(config.usesClientKey, isFalse);
    expect(AiTransportSelection.create(config), isNull);
    expect(AiTransportSelection.create(config), isNot(isA<DirectOpenAiTransport>()));
  });

  test('production proxy never sends mock or OpenAI client keys', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxy,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    final ai = OpenAiOraclyAiService(
      config: config,
      guard: AiRequestGuard(),
      transport: ProxyAiTransport(
        config: config,
      appCheckToken: testAppCheckToken,
        accessToken: () async => 'mock_access_000001',
        client: MockClient((request) async {
          seen = request;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {'text': 'Sakin bir nefes al ve bugunu yumusak tut.'},
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    final result = await ai.chat(userMessage: 'Merhaba, bugun nasilsin?');
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(seen!.url.host, isNot('api.openai.com'));
    expect(seen!.headers['Authorization'], isNull);
    expect(seen!.body, isNot(contains('sk-')));
    expect(seen!.body, isNot(contains('mock_access')));
  });

  test('development may attach a non-OpenAI access token to the proxy', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(proxyUrl: _proxy);
    final ai = OpenAiOraclyAiService(
      config: config,
      guard: AiRequestGuard(),
      transport: ProxyAiTransport(
        config: config,
      appCheckToken: testAppCheckToken,
        accessToken: () async => 'dev-user-token',
        client: MockClient((request) async {
          seen = request;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {'text': 'Sakin bir nefes al ve bugunu yumusak tut.'},
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    await ai.chat(userMessage: 'Merhaba, bugun nasilsin?');
    expect(seen!.headers['Authorization'], 'Bearer dev-user-token');
    expect(seen!.headers['Authorization'], isNot(contains('sk-')));
  });
}
