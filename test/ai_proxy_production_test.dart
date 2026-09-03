/// Production AI proxy contract — Flutter client vs `/backend`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/logging/logger.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/openai/openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/ai_error_mapper.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/coffee_image_limits.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'support/test_app_check_token.dart';

const _proxyUrl = 'https://api.oracly.app/v1/ai/complete';

void main() {
  setUp(AiRequestGuard.shared.reset);

  test('device proxy .env is gitignored and never ships as a Flutter asset', () {
    expect(File('.gitignore').readAsStringSync(), contains('.env'));
    final assetLines = File('pubspec.yaml')
        .readAsStringSync()
        .split('\n')
        .map((l) => l.trim())
        .toList();
    expect(assetLines, isNot(contains('- .env')));
    expect(assetLines, contains('- .env.example'));
    // Root .env must never hold OpenAI secrets (use backend/.env + proxy).
    final env = File('.env');
    if (!env.existsSync()) return;
    for (final line in env.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      expect(trimmed.startsWith('OPENAI_API_KEY='), isFalse);
    }
  });

  test('production without proxy never uses a client OpenAI key', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-secretTESTKEY',
    );
    expect(config.usesProxy, isFalse);
    expect(config.usesClientKey, isFalse);
    expect(config.allowsClientOpenAiKey, isFalse);
    expect(config.isConfigured, isFalse);
    expect(config.toString(), isNot(contains('sk-secret')));
  });

  test('staging without proxy is unconfigured even with a key', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.staging,
      openAiKey: 'sk-secretTESTKEY',
    );
    expect(config.isConfigured, isFalse);
    expect(config.usesClientKey, isFalse);
  });

  test('release-like development build forbids client OpenAI key', () {
    const config = AiRuntimeConfig(
      openAiKey: 'sk-secretTESTKEY',
      simulateReleaseBuild: true,
    );
    expect(config.environment.isDevelopment, isTrue);
    expect(config.usesClientKey, isFalse);
    expect(config.isConfigured, isFalse);
  });

  test('development direct OpenAI is allowed only without proxy', () {
    const direct = AiRuntimeConfig(openAiKey: 'sk-dev-only');
    expect(direct.usesClientKey, isTrue);
    expect(direct.usesProxy, isFalse);
    expect(direct.isConfigured, isTrue);

    const both = AiRuntimeConfig(proxyUrl: _proxyUrl, openAiKey: 'sk-dev-only');
    expect(both.usesProxy, isTrue);
    expect(both.usesClientKey, isFalse);
    expect(both.isConfigured, isTrue);
  });

  test(
    'production key without proxy never activates DirectOpenAiTransport',
    () {
      const config = AiRuntimeConfig(
        environment: AppEnvironment.production,
        openAiKey: 'sk-secretTESTKEY',
      );
      final transport = AiTransportSelection.create(config);
      expect(transport, isNull);
      expect(transport, isNot(isA<DirectOpenAiTransport>()));
      expect(transport, isNot(isA<ProxyAiTransport>()));
    },
  );

  test(
    'proxy URL selects ProxyAiTransport even if a client key is present',
    () {
      const config = AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: _proxyUrl,
        openAiKey: 'sk-SHOULD-NOT-ACTIVATE-DIRECT',
      );
      final transport = AiTransportSelection.create(config);
      expect(transport, isA<ProxyAiTransport>());
      expect(transport, isNot(isA<DirectOpenAiTransport>()));
    },
  );

  test('development without proxy may use DirectOpenAiTransport', () {
    const config = AiRuntimeConfig(openAiKey: 'sk-dev-only');
    final transport = AiTransportSelection.create(config);
    expect(transport, isA<DirectOpenAiTransport>());
    expect(transport, isNot(isA<ProxyAiTransport>()));
  });

  test(
    'production proxy + stray key never sends OpenAI Authorization',
    () async {
      http.Request? seen;
      const config = AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: _proxyUrl,
        openAiKey: 'sk-SHOULD-NOT-BE-SENT',
      );
      expect(config.usesClientKey, isFalse);
      final ai = _service(
        config,
        MockClient((request) async {
          seen = request;
          return _okChat();
        }),
      );
      final result = await ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
      expect(result.isSuccess, isTrue, reason: '${result.failure}');
      expect(seen!.url.toString(), _proxyUrl);
      expect(seen!.headers['Authorization'], 'Bearer test-firebase-access-token');
      expect(seen!.body, isNot(contains('sk-')));
      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body['operation'], 'chat');
      expect(body['model'], 'gpt-4o');
      expect(body['payload']['userMessage'], contains('Merhaba'));
    },
  );

  test('optional real access token is attached, never invented', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
    );
    final transport = ProxyAiTransport(
      config: config,
      appCheckToken: testAppCheckToken,
      accessToken: ({bool forceRefresh = false}) async => 'user-access-token',
      client: MockClient((request) async {
        seen = request;
        return _okChat();
      }),
    );
    final ai = OpenAiOraclyAiService(
      config: config,
      transport: transport,
      guard: AiRequestGuard(),
    );
    await ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    expect(seen, isNotNull);
    expect(seen!.headers['Authorization'], 'Bearer user-access-token');
    expect(seen!.headers['Authorization'], isNot(contains('sk-')));
  });

  test('backend typed errors map to AiFailure without raw bodies', () async {
    final ai = _service(
      _prodProxy,
      MockClient(
        (_) async => _json({
          'success': false,
          'error': {
            'code': 'rate_limit',
            'message': 'sk-leak OpenAI 429 stack',
          },
        }),
      ),
    );
    final result = await ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    expect(result.failure?.kind, AiFailureKind.rateLimit);
    expect(result.failure?.userMessage.toLowerCase(), isNot(contains('sk-')));
    expect(result.failure?.userMessage, isNot(contains('stack')));
  });

  test('chat accepts a short greeting and rejects empty OR text', () async {
    final short = _service(
      _prodProxy,
      MockClient(
        (_) async => _json({
          'success': true,
          'data': {
            'text':
                'Selam. Bugün nasıl hissediyorsun? Buradayım, acele yok.',
          },
        }),
      ),
    );
    final ok = await short.chat(userMessage: 'Selam');
    expect(ok.isSuccess, isTrue);
    expect(ok.value!.text.toLowerCase(), contains('selam'));

    final greeting = _service(
      _prodProxy,
      MockClient(
        (_) async => _json({
          'success': true,
          'data': {
            'text':
                'Merhaba. Sessizce buradayım; ne getirmek istersen dinlerim.',
          },
        }),
      ),
    );
    final kept = await greeting.chat(userMessage: 'Selam');
    expect(kept.isSuccess, isTrue);
    expect(kept.value!.text.trim(), isNotEmpty);

    final empty = _service(
      _prodProxy,
      MockClient(
        (_) async => _json({
          'success': true,
          'data': {'text': '   '},
        }),
      ),
    );
    expect(
      (await empty.chat(userMessage: 'Selam')).failure?.kind,
      AiFailureKind.invalidResponse,
    );
  });

  test('proxy HTTP 429 / timeout / network / invalid envelope', () async {
    expect(AiErrorMapper.fromCode('timeout').kind, AiFailureKind.timeout);
    expect(AiErrorMapper.fromStatus(429).kind, AiFailureKind.rateLimit);

    final timeoutAi = _service(
      const AiRuntimeConfig(
        environment: AppEnvironment.production,
        proxyUrl: _proxyUrl,
        timeout: Duration(milliseconds: 20),
      ),
      MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return _okChat();
      }),
    );
    expect(
      (await timeoutAi.chat(
        userMessage: 'Merhaba, bugün nasılsın?',
      )).failure?.kind,
      AiFailureKind.timeout,
    );

    final networkAi = _service(
      _prodProxy,
      MockClient((_) async => throw const SocketException('offline')),
    );
    expect(
      (await networkAi.chat(
        userMessage: 'Merhaba, bugün nasılsın?',
      )).failure?.kind,
      AiFailureKind.network,
    );

    final invalidAi = _service(
      _prodProxy,
      MockClient(
        (_) async => _json({'success': true, 'data': 'not-an-object'}),
      ),
    );
    expect(
      (await invalidAi.chat(
        userMessage: 'Merhaba, bugün nasılsın?',
      )).failure?.kind,
      AiFailureKind.invalidResponse,
    );
  });

  test('dream analysis goes through proxy with structured payload', () async {
    http.Request? seen;
    final ai = _service(
      _prodProxy,
      MockClient((request) async {
        seen = request;
        return _json({
          'success': true,
          'data': {
            'summary': 'Rüya sakin bir geçiş hissi taşıyor.',
            'symbols': ['yılan'],
            'emotionalTheme': 'Belirsizlik ve yenilenme.',
            'interpretation':
                'Yılan burada tehdit değil, bir dönüşüm izi olabilir.',
            'dailyLifeReflection':
                'Bugün acele etmeden bir adım geri durmak iyi gelir.',
            'conclusion': 'Bu rüya bir uyarı değil, bir davettir.',
          },
        });
      }),
    );
    final result = await ai.analyzeDream(
      const DreamAiContext(narrative: 'Rüyamda uzun bir yılan evden geçti.'),
    );
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.value?.symbols, ['yılan']);
    final body = jsonDecode(seen!.body) as Map<String, dynamic>;
    expect(body['operation'], 'dream_analysis');
    expect(body['payload']['narrative'], contains('yılan'));
    expect(seen!.headers['Authorization'], 'Bearer test-firebase-access-token');
  });

  test(
    'OR a Sor preserves isolated structured context through proxy',
    () async {
      final kinds = <String>[];
      final ai = _service(
        _prodProxy,
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['operation'], 'oracle');
          kinds.add(
            (body['payload']['context'] as Map<String, dynamic>)['kind']
                as String,
          );
          return _okChat();
        }),
      );
      await ai.askOracle(
        context: const TarotAiContext(
          sessionId: 's1',
          spreadLabel: 'Tek kart',
          readingTitle: 'Bugün',
          cardsSummary: 'The Moon',
          interpretationSummary: 'Sis ve sezgi.',
        ),
        userMessage: 'Bu kart bana ne söylüyor?',
      );
      await ai.askOracle(
        context: const DreamAiContext(
          narrative: 'Rüyamda deniz vardı ve yürüdüm.',
        ),
        userMessage: 'Bu rüya ne anlatıyor?',
      );
      await ai.askOracle(
        context: const CoffeeAiContext(overall: 'Duruluk ve sakin bir iz.'),
        userMessage: 'Fincan neye işaret ediyor?',
      );
      expect(kinds, ['tarot', 'dream', 'coffee']);
    },
  );

  test('coffee vision goes through proxy with size and mime limits', () async {
    http.Request? seen;
    // Valid JPEG magic so client mime sniff accepts the payload.
    final bytes = <int>[
      0xff,
      0xd8,
      0xff,
      0xe0,
      ...List<int>.filled(CoffeeImageLimits.minBytes + 20, 0x7F),
    ];
    final ai = _service(
      _prodProxy,
      MockClient((request) async {
        seen = request;
        return _json({
          'success': true,
          'data': {
            'visualObservation': 'Fincanda dağınık ince izler görünüyor.',
            'overall': 'Bu fincan sakin bir duruluk hissi taşıyor.',
            'love': 'İlişkide yumuşak bir nefes alanı var burada.',
            'career': 'İş tarafında acele etmeden ilerlemek iyi gelir.',
            'money': 'Maddi konularda ölçülü kalmak faydalı olabilir.',
            'nearFuture': 'Yakın dönemde sakin bir tempo uygun görünüyor.',
            'takeaway': 'Bugün biraz daha yavaş olmak iyi gelir.',
            'symbols': [
              {
                'name': 'Kuş',
                'meaning': 'Haber',
                'interpretation': 'Hafif bir haber hissi.',
              },
            ],
          },
        });
      }),
    );
    final ok = await ai.analyzeCoffee(
      imageBytes: bytes,
      mimeType: 'image/jpeg',
    );
    expect(ok.isSuccess, isTrue);
    expect(ok.value?.visualObservation, contains('ince izler'));
    expect(ok.value?.symbols.single.name, 'Kuş');
    final body = jsonDecode(seen!.body) as Map<String, dynamic>;
    expect(body['operation'], 'coffee_analysis');
    expect(body['payload']['mimeType'], 'image/jpeg');
    expect(body['payload']['byteLength'], bytes.length);
    expect(body['payload']['imageBase64'], isA<String>());
    expect(seen!.body.toLowerCase(), isNot(contains('sk-')));

    final tiny = await ai.analyzeCoffee(
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
    );
    expect(tiny.failure?.kind, AiFailureKind.invalidResponse);

    final noMagic = List<int>.filled(CoffeeImageLimits.minBytes + 24, 0x7F);
    final badMime = await ai.analyzeCoffee(
      imageBytes: noMagic,
      mimeType: 'image/gif',
    );
    expect(badMime.failure?.kind, AiFailureKind.invalidResponse);
  });

  test('AI chat duplicate in-flight requests share one proxy call', () async {
    var calls = 0;
    final gate = Completer<void>();
    final ai = OpenAiOraclyAiService(
      config: _prodProxy,
      guard: AiRequestGuard(),
      transport: ProxyAiTransport(
        config: _prodProxy,
        appCheckToken: testAppCheckToken,
        accessToken: testAccessToken,
        client: MockClient((_) async {
          calls += 1;
          await gate.future;
          return _okChat();
        }),
      ),
    );
    final first = ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    final second = ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    gate.complete();
    final a = await first;
    final b = await second;
    expect(a.isSuccess, isTrue);
    expect(b.isSuccess, isTrue);
    expect(calls, 1);
  });

  test('direct OpenAI fallback refuses production config', () async {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-secretTESTKEY',
    );
    final transport = DirectOpenAiTransport(
      config: config,
      client: MockClient((_) async => fail('must not call OpenAI')),
    );
    final outcome = await transport.execute(
      const AiProxyRequest(
        operation: AiOperation.chat,
        payload: {'userMessage': 'Merhaba'},
      ),
    );
    expect(outcome.failure?.kind, AiFailureKind.noConfiguration);
  });

  test('development direct OpenAI still hits api.openai.com', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(openAiKey: 'sk-dev-only');
    final ai = OpenAiOraclyAiService(
      config: config,
      guard: AiRequestGuard(),
      transport: DirectOpenAiTransport(
        config: config,
        openAi: OpenAiTransport(
          config: config,
          client: MockClient((request) async {
            seen = request;
            return _json({
              'choices': [
                {
                  'message': {
                    'content': 'Sakin bir nefes al ve bugünü yumuşak tut.',
                  },
                },
              ],
            });
          }),
        ),
      ),
    );
    final result = await ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(seen!.url.toString(), AiRuntimeConfig.openAiChatUrl);
    expect(seen!.headers['Authorization'], 'Bearer sk-dev-only');
  });

  test('vision unavailable stays explicit when vision is off', () async {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _proxyUrl,
      visionEnabled: false,
    );
    final ai = OpenAiOraclyAiService(
      config: config,
      transport: ProxyAiTransport(
        config: config,
        appCheckToken: testAppCheckToken,
        accessToken: testAccessToken,
        client: MockClient((_) async => fail('must not call proxy')),
      ),
    );
    final coffee = await ai.analyzeCoffee(
      imageBytes: List<int>.filled(CoffeeImageLimits.minBytes + 8, 1),
      mimeType: 'image/jpeg',
    );
    expect(coffee.failure?.kind, AiFailureKind.imageAnalysisUnavailable);
  });

  test('.env.example never carries an uncommented live OPENAI_API_KEY', () {
    final file = File('.env.example');
    expect(file.existsSync(), isTrue);
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      expect(
        trimmed.toUpperCase().startsWith('OPENAI_API_KEY='),
        isFalse,
        reason: 'Live OPENAI_API_KEY must not appear in Flutter asset '
            '.env.example (line: $trimmed)',
      );
    }
  });

  test('gitignore covers secret env variants and allowlists example', () {
    final ignore = File('.gitignore').readAsStringSync();
    expect(ignore, contains('.env.*'));
    expect(ignore, contains('!.env.example'));
    expect(ignore, contains('backend/.env'));
  });

  test('Logger.scrub redacts provider keys and bearer tokens', () {
    expect(
      Logger.scrub('fail sk-proj-ABCDEFGHIJKLMNOP password'),
      isNot(contains('sk-proj-ABCDEFGHIJKLMNOP')),
    );
    expect(
      Logger.scrub('Authorization: Bearer user-token-xyz'),
      contains('[redacted]'),
    );
    expect(
      Logger.scrub('OPENAI_API_KEY=sk-should-hide'),
      isNot(contains('sk-should-hide')),
    );
  });
}

const _prodProxy = AiRuntimeConfig(
  environment: AppEnvironment.production,
  proxyUrl: _proxyUrl,
);

OpenAiOraclyAiService _service(AiRuntimeConfig config, MockClient client) {
  return OpenAiOraclyAiService(
    config: config,
    transport: ProxyAiTransport(
      config: config,
      appCheckToken: testAppCheckToken,
      accessToken: testAccessToken,
      client: client,
    ),
    guard: AiRequestGuard(),
  );
}

http.Response _okChat() {
  return _json({
    'success': true,
    'data': {'text': 'Sakin bir nefes al ve bugünü yumuşak tut.'},
  });
}

http.Response _json(Map<String, dynamic> body, [int status = 200]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
