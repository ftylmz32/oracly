/// Soul-mate proxy transport ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â no direct OpenAI, no secret leakage.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_providers.dart';
import 'package:oracly_new/features/premium/services/proxy_soul_mate_draw.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/unavailable_soul_mate_draw.dart';
import '../../support/test_app_check_token.dart';

const _proxyUrl = 'https://api.oracly.app/v1/ai/complete';
const _tinyPngB64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  test('authenticated soulmate_draw reaches proxy only', () async {
    AiRequestGuard.shared.reset();
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
    );
    final port = ProxySoulMateDraw(
      transport: ProxyAiTransport(
        config: config,
      appCheckToken: testAppCheckToken,
        accessToken: ({bool forceRefresh = false}) async => 'user-access-token',
        client: MockClient((request) async {
          seen = request;
          return _okPortrait();
        }),
      ),
    );
    final result = await port.draw(
      SoulMateDrawRequest(
        name: 'Elif',
        birthDate: DateTime(1994, 3, 12),
        gender: SoulMateGenderPref.feminine,
        intention: 'sakin',
      ),
    );
    expect(result.hasPortrait, isTrue);
    expect(result.imageBytes, isNotEmpty);
    expect(seen!.url.toString(), _proxyUrl);
    expect(seen!.url.toString(), isNot(contains('openai.com')));
    expect(seen!.headers['Authorization'], 'Bearer user-access-token');
    expect(seen!.headers['Authorization'], isNot(contains('sk-')));
    expect(seen!.body, isNot(contains('sk-')));
    expect(seen!.body, isNot(contains('prompt')));
    final body = jsonDecode(seen!.body) as Map<String, dynamic>;
    expect(body['operation'], 'soulmate_draw');
    expect(body.containsKey('model'), isFalse);
    expect(body['payload']['name'], 'Elif');
    expect(body['payload']['birthDate'], '1994-03-12');
    expect(body['payload']['gender'], 'feminine');
    expect(body['payload']['intention'], 'sakin');
  });

  test('proxy errors map without leaking provider bodies', () async {
    AiRequestGuard.shared.reset();
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
    );
    Future<SoulMateDrawResult> run(http.Response response) {
      return ProxySoulMateDraw(
        transport: ProxyAiTransport(
          config: config,
          appCheckToken: testAppCheckToken,
          accessToken: testAccessToken,
          client: MockClient((_) async => response),
        ),
      ).draw(
        SoulMateDrawRequest(name: 'Elif', birthDate: DateTime(1994, 3, 12)),
      );
    }

    final limited = await run(
      _json({
        'success': false,
        'error': {'code': 'rate_limited', 'message': 'sk-leak OpenAI 429'},
      }),
    );
    expect(limited.hasPortrait, isFalse);
    expect(limited.message, ResilienceCopy.aiRateLimited);
    expect(limited.message, isNot(contains('sk-')));

    final missing = await run(
      _json({
        'success': false,
        'error': {'code': 'no_configuration'},
      }),
    );
    expect(missing.message, ResilienceCopy.aiConfigMissing);

    final provider = await run(
      _json({
        'success': false,
        'error': {'code': 'provider_error'},
      }),
    );
    expect(provider.message, ResilienceCopy.aiUnavailable);
  });

  test('direct OpenAI transport never generates soulmate images', () async {
    const config = AiRuntimeConfig(openAiKey: 'sk-dev-only');
    final transport = DirectOpenAiTransport(
      config: config,
      client: MockClient((_) async => fail('must not call OpenAI')),
    );
    final outcome = await transport.execute(
      const AiProxyRequest(
        operation: AiOperation.soulmateDraw,
        payload: {'name': 'Elif', 'birthDate': '1994-03-12'},
      ),
    );
    expect(outcome.isFailure, isTrue);
    expect(outcome.failure?.kind, AiFailureKind.noConfiguration);
  });

  test('provider stays unavailable without proxy', () {
    final container = ProviderContainer(
      overrides: [
        aiRuntimeConfigProvider.overrideWithValue(
          const AiRuntimeConfig(openAiKey: 'sk-dev-only'),
        ),
        aiTransportProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    expect(
      container.read(soulMateDrawPortProvider),
      isA<UnavailableSoulMateDraw>(),
    );
  });

  test('provider uses proxy port when proxy is configured', () {
    final container = ProviderContainer(
      overrides: [
        aiRuntimeConfigProvider.overrideWithValue(
          const AiRuntimeConfig(
            environment: AppEnvironment.production,
            proxyUrl: _proxyUrl,
          ),
        ),
        aiTransportProvider.overrideWithValue(
          ProxyAiTransport(
            appCheckToken: testAppCheckToken,
            accessToken: testAccessToken,
            config: const AiRuntimeConfig(
              environment: AppEnvironment.production,
              proxyUrl: _proxyUrl,
            ),
            client: MockClient((_) async => _okPortrait()),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(soulMateDrawPortProvider), isA<ProxySoulMateDraw>());
    expect(
      AiTransportSelection.create(
        const AiRuntimeConfig(
          environment: AppEnvironment.production,
          proxyUrl: _proxyUrl,
        ),
      ),
      isA<ProxyAiTransport>(),
    );
  });

  test('soulmate flutter sources never call OpenAI directly', () {
    const files = [
      'lib/features/premium/services/proxy_soul_mate_draw.dart',
      'lib/features/premium/providers/soul_mate_providers.dart',
      'lib/features/ai/production/openai/openai_service_requests.dart',
      'lib/features/ai/production/openai/openai_service_results.dart',
    ];
    for (final path in files) {
      final src = File(path).readAsStringSync();
      expect(src, isNot(contains('api.openai.com')));
      expect(src, isNot(contains('/images/generations')));
      expect(src, isNot(contains('OPENAI_API_KEY')));
      expect(src.toLowerCase(), isNot(contains('sk-')));
    }
  });
  test('auth failure maps without inventing a portrait', () async {
    AiRequestGuard.shared.reset();
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
    );
    final result = await ProxySoulMateDraw(
      transport: ProxyAiTransport(
        config: config,
      appCheckToken: testAppCheckToken,
        accessToken: ({bool forceRefresh = false}) async => 'expired-token',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': {'code': 'unauthorized'},
            }),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      ),
    ).draw(
      SoulMateDrawRequest(name: 'Elif', birthDate: DateTime(1994, 3, 12)),
    );
    expect(result.hasPortrait, isFalse);
    expect(result.message, ResilienceCopy.aiUnauthorized);
  });

  test('malformed imageBase64 fails closed', () async {
    AiRequestGuard.shared.reset();
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
    );
    final result = await ProxySoulMateDraw(
      transport: ProxyAiTransport(
        config: config,
        appCheckToken: testAppCheckToken,
        accessToken: testAccessToken,
        client: MockClient(
          (_) async => _json({
            'success': true,
            'data': {
              'imageBase64': base64Encode(utf8.encode('not-an-image')),
              'mimeType': 'image/png',
            },
          }),
        ),
      ),
    ).draw(
      SoulMateDrawRequest(name: 'Elif', birthDate: DateTime(1994, 3, 12)),
    );
    expect(result.hasPortrait, isFalse);
    expect(result.message, ResilienceCopy.aiEmptyResponse);
  });

  test('duplicate in-flight soulmate draws share one proxy call', () async {
    AiRequestGuard.shared.reset();
    var hits = 0;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
    );
    final port = ProxySoulMateDraw(
      transport: ProxyAiTransport(
        config: config,
        appCheckToken: testAppCheckToken,
        accessToken: testAccessToken,
        client: MockClient((_) async {
          hits += 1;
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return _okPortrait();
        }),
      ),
    );
    final request = SoulMateDrawRequest(
      name: 'Elif',
      birthDate: DateTime(1994, 3, 12),
    );
    final results = await Future.wait([port.draw(request), port.draw(request)]);
    expect(hits, 1);
    expect(results.every((r) => r.hasPortrait), isTrue);
  });

  test('no proxy keeps UnavailableSoulMateDraw (entitlement infra ready, AI not)',
      () {
    final container = ProviderContainer(
      overrides: [
        aiRuntimeConfigProvider.overrideWithValue(
          const AiRuntimeConfig(environment: AppEnvironment.production),
        ),
        aiTransportProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    final port = container.read(soulMateDrawPortProvider);
    expect(port, isA<UnavailableSoulMateDraw>());
    expect(port.isAvailable, isFalse);
  });
}

http.Response _okPortrait() {
  return _json({
    'success': true,
    'data': {
      'imageBase64': _tinyPngB64,
      'mimeType': 'image/png',
      'operation': 'soulmate_draw',
    },
  });
}

http.Response _json(Map<String, dynamic> body) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}