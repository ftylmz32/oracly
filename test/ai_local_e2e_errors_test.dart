/// Local REAL E2E errors + production key safety. Skip unless ORACLY_E2E=1.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';

import 'support/ai_e2e_probe.dart';
import 'support/test_app_check_token.dart';

bool get _e2e => Platform.environment['ORACLY_E2E'] == '1';

void main() {
  final skip = _e2e ? false : 'Set ORACLY_E2E=1 with local Fastify running';

  setUpAll(() async {
    if (_e2e) await detectE2eProvider();
  });

  test(
    'backend unavailable + invalid + timeout → Turkish AiFailure',
    () async {
      final unavailable = await e2eAi(
        e2eDeadProxyUrl,
      ).chat(userMessage: 'Merhaba, nasilsin?');
      expect(unavailable.failure?.kind, AiFailureKind.network);
      expect(unavailable.failure?.userMessage, ResilienceCopy.aiUnavailable);
      assertCleanError(unavailable.failure!.userMessage);

      // Missing-key assertion is only valid when the live proxy has no provider.
      // When keyed, the same endpoint succeeds (or rate-limits honestly).
      final live = await e2eAi(
        e2eProxyUrl,
      ).chat(userMessage: 'Merhaba, nasilsin?');
      e2eFailIfRateLimited(live.failure?.kind, live.failure?.userMessage);
      if (e2eProviderConfigured) {
        expect(live.isSuccess, isTrue, reason: '${live.failure}');
        expect(live.value!.text.trim().length, greaterThan(5));
      } else {
        expect(live.failure?.kind, AiFailureKind.noConfiguration);
        expect(live.failure?.userMessage, ResilienceCopy.aiConfigMissing);
        assertCleanError(live.failure!.userMessage);
      }

      const tiny = AiRuntimeConfig(
        proxyUrl: 'http://192.0.2.1:8787/v1/ai/complete',
        timeout: Duration(milliseconds: 400),
      );
      final timed = await OpenAiOraclyAiService(
        config: tiny,
        transport: ProxyAiTransport(
          appCheckToken: testAppCheckToken,
          accessToken: testAccessToken,
          config: tiny,
        ),
      ).chat(userMessage: 'Merhaba, bugun nasilsin acaba?');
      expect(
        timed.failure?.kind,
        anyOf(AiFailureKind.timeout, AiFailureKind.network),
      );
      assertCleanError(timed.failure!.userMessage);

      final invalid = await ProxyAiTransport(
        config: const AiRuntimeConfig(proxyUrl: e2eProxyUrl),
        appCheckToken: testAppCheckToken,
        accessToken: testAccessToken,
      ).execute(const AiProxyRequest(operation: AiOperation.chat, payload: {}));
      expect(invalid.failure?.kind, AiFailureKind.invalidResponse);
      expect(invalid.failure?.userMessage, ResilienceCopy.aiEmptyResponse);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test('optional auth server: unauthorized + rate limit', () async {
    try {
      final health = await http.get(Uri.parse('http://127.0.0.1:8788/health'));
      if (health.statusCode != 200) {
        markTestSkipped('Auth test server :8788 not running.');
        return;
      }
    } catch (_) {
      markTestSkipped(
        'Auth test server :8788 not running. Production auth/rate-limit '
        'live path not exercised this run (backend unit tests cover it).',
      );
      return;
    }

    final unauthorized = await e2eAi(
      e2eAuthProxyUrl,
    ).chat(userMessage: 'Merhaba, nasilsin?');
    expect(unauthorized.failure?.kind, AiFailureKind.unauthorized);
    expect(unauthorized.failure?.userMessage, ResilienceCopy.aiUnauthorized);

    final limited = e2eAi(
      e2eAuthProxyUrl,
      token: ({bool forceRefresh = false}) async => 'rate-e2e-token',
    );
    await limited.chat(userMessage: 'Merhaba, nasilsin?');
    await limited.chat(userMessage: 'Merhaba, nasilsin?');
    final third = await limited.chat(userMessage: 'Merhaba, nasilsin?');
    expect(third.failure?.kind, AiFailureKind.rateLimit);
    expect(third.failure?.userMessage, ResilienceCopy.aiRateLimited);
  }, skip: skip);

  test('production without proxy never calls OpenAI', () async {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    expect(config.isConfigured, isFalse);
    expect(AiTransportSelection.create(config), isNull);
    final probe = AiE2eProbe();
    final direct = DirectOpenAiTransport(config: config, client: probe);
    final outcome = await direct.execute(
      const AiProxyRequest(
        operation: AiOperation.chat,
        payload: {'userMessage': 'Merhaba'},
      ),
    );
    expect(outcome.failure?.kind, AiFailureKind.noConfiguration);
    expect(probe.requests, isEmpty);
    final unconfigured = await const UnconfiguredOraclyAiService().chat(
      userMessage: 'Merhaba, nasilsin?',
    );
    expect(unconfigured.failure?.userMessage, ResilienceCopy.aiConfigMissing);
  }, skip: skip);
}
