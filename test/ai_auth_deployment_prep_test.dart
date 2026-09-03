/// Auth/deployment prep — production blocks mock tokens; IdP tokens may attach.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_headers.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'support/test_app_check_token.dart';

const _proxy = 'https://api.oracly.app/v1/ai/complete';

/// Production-shaped fake JWT (not mock_*, not sk-).
const _prodShapedToken =
    'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.prod-shaped-signature';

void main() {
  test('production never falls back to direct OpenAI', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-SHOULD-NOT-BE-USED',
    );
    expect(config.usesClientKey, isFalse);
    expect(AiTransportSelection.create(config), isNull);
    expect(
      AiTransportSelection.create(config),
      isNot(isA<DirectOpenAiTransport>()),
    );
  });

  test('production rejects mock_* tokens and never sends them', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxy,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    expect(
      ProxyAiHeaders.maySendUserToken(config, 'mock_access_000001'),
      isFalse,
    );
    final ai = OpenAiOraclyAiService(
      config: config,
      guard: AiRequestGuard(),
      transport: ProxyAiTransport(
        config: config,
        appCheckToken: testAppCheckToken,
        accessToken: ({bool forceRefresh = false}) async =>
            'mock_access_000001',
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
    expect(result.isSuccess, isFalse, reason: '${result.failure}');
    expect(
      result.failure?.kind,
      anyOf(AiFailureKind.authPending, AiFailureKind.unauthorized),
    );
    expect(seen, isNull);
  });

  test('production proxy may attach a non-mock access token', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxy,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    expect(ProxyAiHeaders.maySendUserToken(config, _prodShapedToken), isTrue);
    final ai = OpenAiOraclyAiService(
      config: config,
      guard: AiRequestGuard(),
      transport: ProxyAiTransport(
        config: config,
        appCheckToken: testAppCheckToken,
        accessToken: ({bool forceRefresh = false}) async => _prodShapedToken,
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
    expect(seen!.headers['Authorization'], 'Bearer $_prodShapedToken');
    expect(seen!.headers['Authorization'], isNot(contains('sk-')));
    expect(seen!.headers['Authorization'], isNot(contains('mock_')));
    expect(seen!.body, isNot(contains('sk-')));
    expect(seen!.body, isNot(contains('mock_access')));
  });

  test(
    'development may attach a non-OpenAI access token to the proxy',
    () async {
      http.Request? seen;
      const config = AiRuntimeConfig(proxyUrl: _proxy);
      final ai = OpenAiOraclyAiService(
        config: config,
        guard: AiRequestGuard(),
        transport: ProxyAiTransport(
          config: config,
          appCheckToken: testAppCheckToken,
          accessToken: ({bool forceRefresh = false}) async => 'dev-user-token',
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
    },
  );
}
