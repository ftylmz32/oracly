/// Production fail-closed: no local AI, no direct OpenAI without proxy.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'support/test_app_check_token.dart';

const _prodProxy = 'https://api.oracly.app/v1/ai/complete';
const _lanProxy = 'http://192.168.1.20:8787/v1/ai/complete';

void main() {
  test('production + no proxy → noConfiguration, no local, no direct OpenAI',
      () async {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-SHOULD-NOT-BE-USED',
    );
    expect(config.isConfigured, isFalse);
    expect(config.usesClientKey, isFalse);
    expect(config.allowsLocalFallback, isFalse);
    expect(AiTransportSelection.create(config), isNull);

    const ai = UnconfiguredOraclyAiService();
    expect(ai.allowsLocalFallback, isFalse);
    final chat = await ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    expect(chat.failure?.kind, AiFailureKind.noConfiguration);
    expect(chat.failure?.userMessage, ResilienceCopy.aiConfigMissing);
  });

  test('production unconfigured never uses companion/oracle/dream locals',
      () async {
    const ai = UnconfiguredOraclyAiService();
    await expectLater(
      CompanionAiBridge(ai).tryLiveOrFailClosed(
        userMessage: 'Merhaba, nasılsın?',
      ),
      throwsA(_noConfig),
    );
    await expectLater(
      OracleAiMessageSource(ai: ai).reply(
        context: _tarot(),
        userMessage: 'Bu kart ne anlatıyor?',
      ),
      throwsA(_noConfig),
    );
    await expectLater(
      DreamExperienceService(repository: _MemDreams(), ai: ai).analyze(
        narrative: 'Rüyamda uzun bir yılan evden geçti.',
      ),
      throwsA(_noConfig),
    );
  });

  test('development unconfigured may use local responders', () async {
    const ai = UnconfiguredOraclyAiService(allowsLocalFallback: true);
    expect(
      await CompanionAiBridge(ai).tryLiveOrFailClosed(userMessage: 'Merhaba'),
      isNull,
    );
    final oracle = await OracleAiMessageSource(ai: ai).reply(
      context: _tarot(),
      userMessage: 'Bu kart ne anlatıyor?',
    );
    expect(oracle.trim(), isNotEmpty);
    final dream = await DreamExperienceService(
      repository: _MemDreams(),
      ai: ai,
    ).analyze(narrative: 'Rüyamda uzun bir yılan evden geçti.');
    expect(dream.dream.insights, isNotEmpty);
  });

  test('production + proxy uses ProxyAiTransport even with stray key', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _prodProxy,
      openAiKey: 'sk-SHOULD-NOT-ACTIVATE-DIRECT',
    );
    expect(config.allowsLocalFallback, isFalse);
    expect(config.usesClientKey, isFalse);
    final transport = AiTransportSelection.create(config);
    expect(transport, isA<ProxyAiTransport>());
    expect(transport, isNot(isA<DirectOpenAiTransport>()));
    expect(
      OpenAiOraclyAiService(config: config, transport: transport!)
          .allowsLocalFallback,
      isFalse,
    );
  });

  test('production stray client key is never sent', () async {
    http.Request? seen;
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _prodProxy,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    final ai = OpenAiOraclyAiService(
      config: config,
      transport: ProxyAiTransport(
        config: config,
      appCheckToken: testAppCheckToken,
        client: MockClient((request) async {
          seen = request;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {
                  'text': 'Sakin bir nefes al ve bugunu yumusak tut.',
                },
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    final result = await ai.chat(userMessage: 'Merhaba, bugün nasılsın?');
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(seen!.url.toString(), _prodProxy);
    expect(seen!.url.host, isNot('api.openai.com'));
    expect(seen!.headers['Authorization'], isNull);
    expect(seen!.body, isNot(contains('sk-')));
  });

  test('development direct OpenAI remains possible without proxy', () {
    const config = AiRuntimeConfig(openAiKey: 'sk-dev-only');
    expect(config.allowsClientOpenAiKey, isTrue);
    expect(config.usesClientKey, isTrue);
    expect(config.allowsLocalFallback, isFalse);
    expect(AiTransportSelection.create(config), isA<DirectOpenAiTransport>());
  });

  test('LAN proxy allowed in development; rejected in production', () {
    const lanDev = AiRuntimeConfig(proxyUrl: _lanProxy);
    expect(lanDev.usesProxy, isTrue);
    expect(AiTransportSelection.create(lanDev), isA<ProxyAiTransport>());

    const prodBare = AiRuntimeConfig(
      environment: AppEnvironment.production,
    );
    expect(prodBare.usesProxy, isFalse);
    expect(prodBare.allowsLocalFallback, isFalse);
    expect(AiTransportSelection.create(prodBare), isNull);

    const prodLan = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: _lanProxy,
    );
    expect(prodLan.usesProxy, isFalse);
    expect(prodLan.isConfigured, isFalse);
    expect(AiTransportSelection.create(prodLan), isNull);
    expect(prodLan.usesClientKey, isFalse);
  });

  test('production and release reject loopback proxy as unconfigured', () {
    const prodLoop = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: 'http://127.0.0.1:8787/v1/ai/complete',
    );
    expect(prodLoop.usesProxy, isFalse);
    expect(prodLoop.isConfigured, isFalse);
    expect(AiTransportSelection.create(prodLoop), isNull);

    const releaseLoop = AiRuntimeConfig(
      proxyUrl: 'http://localhost:8787/v1/ai/complete',
      simulateReleaseBuild: true,
    );
    expect(releaseLoop.usesProxy, isFalse);
    expect(releaseLoop.allowsLocalFallback, isFalse);
    expect(AiTransportSelection.create(releaseLoop), isNull);
  });
}

final _noConfig = isA<AiRequestException>().having(
  (e) => e.failure.kind,
  'kind',
  AiFailureKind.noConfiguration,
);

OracleReadingContext _tarot() {
  return const OracleReadingContext(
    sessionId: 'tarot_1',
    kind: OracleReadingKind.tarot,
    sourceLabel: 'Tarot',
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    deckName: 'Rider-Waite',
    readingTitle: 'Üç Kart Açılımı',
    cardsSummary: 'Geçmiş: The Fool (Düz)',
    interpretationSummary: 'Bağ ve net konuşma öne çıkıyor.',
    cardNames: ['The Fool'],
  );
}

class _MemDreams implements DreamRepository {
  final List<DreamRecord> _all = [];

  @override
  Future<List<DreamRecord>> getAll() async => List.of(_all);

  @override
  Future<DreamRecord?> getById(String id) async {
    for (final row in _all) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  Future<void> save(DreamRecord record) async {
    _all.removeWhere((e) => e.id == record.id);
    _all.add(record);
  }

  @override
  Future<void> delete(String id) async => _all.removeWhere((e) => e.id == id);

  @override
  Future<void> sync() async {}
}
