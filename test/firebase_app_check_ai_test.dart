/// Firebase App Check policy + header contract tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/auth/firebase/firebase_app_check_policy.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_headers.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';

import 'support/test_app_check_token.dart';

const _proxy = 'https://api.oracly.app/v1/ai/complete';
const _prod = AiRuntimeConfig(
  environment: AppEnvironment.production,
  proxyUrl: _proxy,
);

void main() {
  setUp(AiRequestGuard.shared.reset);

  test('debug App Check provider cannot activate when release-locked', () {
    expect(
      FirebaseAppCheckPolicy.useDebugProvider(
        environment: AppEnvironment.development,
        releaseLocked: true,
      ),
      isFalse,
    );
    expect(
      FirebaseAppCheckPolicy.useDebugProvider(
        environment: AppEnvironment.development,
        releaseLocked: false,
      ),
      isTrue,
    );
  });

  test('production proxy requires App Check token', () {
    expect(ProxyAiHeaders.requiresAppCheck(_prod), isTrue);
  });

  test('AI request includes Auth and App Check headers', () async {
    http.Request? seen;
    final result = await OpenAiOraclyAiService(
      config: _prod,
      transport: ProxyAiTransport(
        config: _prod,
        accessToken: ({bool forceRefresh = false}) async => 'firebase-id-token',
        appCheckToken: testAppCheckToken,
        client: MockClient((request) async {
          seen = request;
          return http.Response(
            '{"success":true,"data":{"text":"Sakin bir nefes al ve dinle."}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      guard: AiRequestGuard(),
    ).chat(userMessage: 'Merhaba, bugun nasilsin?');
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(seen!.headers['Authorization'], 'Bearer firebase-id-token');
    expect(seen!.headers[ProxyAiHeaders.appCheckHeader], 'test-app-check-token');
    expect(seen!.headers['Idempotency-Key'], startsWith('or-'));
    expect(seen!.body, isNot(contains('test-app-check-token')));
  });

  test('missing App Check token prevents production AI request', () async {
    var called = false;
    final outcome = await ProxyAiTransport(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => 'firebase-id-token',
      appCheckToken: ({bool forceRefresh = false}) async => null,
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    ).execute(
      const AiProxyRequest(
        operation: AiOperation.chat,
        model: 'gpt-4o',
        payload: {'userMessage': 'Merhaba, bugun nasilsin?'},
      ),
    );
    expect(called, isFalse);
    expect(outcome.failure?.kind, AiFailureKind.appCheck);
    expect(outcome.failure?.userMessage.toLowerCase(), isNot(contains('token')));
  });

  test('shared ProxyAiTransport path wires App Check once', () {
    expect(
      AiTransportSelection.create(
        _prod,
        accessToken: ({bool forceRefresh = false}) async => 't',
        appCheckToken: testAppCheckToken,
      ),
      isA<ProxyAiTransport>(),
    );
  });

  test('request body contract unchanged when App Check present', () async {
    http.Request? seen;
    await ProxyAiTransport(
      config: _prod,
      accessToken: ({bool forceRefresh = false}) async => 'firebase-id-token',
      appCheckToken: testAppCheckToken,
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          '{"success":true,"data":{"text":"Sakin bir nefes al ve dinle."}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ).execute(
      const AiProxyRequest(
        operation: AiOperation.chat,
        model: 'gpt-4o',
        payload: {'userMessage': 'Merhaba, bugun nasilsin?', 'priorUser': []},
      ),
    );
    expect(seen!.body, contains('"operation":"chat"'));
    expect(seen!.body, isNot(contains('X-Firebase-AppCheck')));
  });
}
