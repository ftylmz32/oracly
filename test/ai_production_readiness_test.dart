/// AI production readiness — service, errors, parsers, context isolation.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/contexts/oracle_context_mapper.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/coffee_vision_parser.dart';
import 'package:oracly_new/features/ai/production/openai/dream_analysis_parser.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/openai/openai_status_mapper.dart';
import 'package:oracly_new/features/ai/production/openai/openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_parser.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

void main() {
  test('typed failures stay Turkish and never include secrets', () {
    expect(AiFailure.noConfiguration().userMessage, ResilienceCopy.aiConfigMissing);
    expect(AiFailure.network().userMessage, ResilienceCopy.aiUnavailable);
    expect(AiFailure.timeout().userMessage, ResilienceCopy.slowResponse);
    expect(AiFailure.rateLimit().userMessage, ResilienceCopy.aiRateLimited);
    expect(AiFailure.invalidResponse().userMessage, ResilienceCopy.aiEmptyResponse);
    expect(AiFailure.providerError().userMessage, ResilienceCopy.aiUnavailable);
    expect(
      AiFailure.imageAnalysisUnavailable().userMessage,
      CoffeeCopy.analysisUnavailable,
    );
    for (final failure in [
      AiFailure.noConfiguration(),
      AiFailure.providerError(),
      AiFailure.rateLimit(),
    ]) {
      expect(failure.userMessage.toLowerCase(), isNot(contains('sk-')));
      expect(failure.userMessage.toLowerCase(), isNot(contains('api_key')));
      expect(failure.toString(), isNot(contains('sk-')));
    }
  });

  test('runtime config never prints the API key', () {
    const config = AiRuntimeConfig(
      openAiKey: 'sk-secretTESTKEY',
      model: 'gpt-4o',
    );
    expect(config.isConfigured, isTrue);
    expect(config.usesClientKey, isTrue);
    expect(config.toString(), isNot(contains('sk-secret')));
    expect(config.toString(), contains('clientKey: present'));
  });

  test('unconfigured service returns typed errors, not fake copy', () async {
    const ai = UnconfiguredOraclyAiService();
    expect(ai.isConfigured, isFalse);
    expect(ai.visionAvailable, isFalse);
    final chat = await ai.chat(userMessage: 'Merhaba');
    expect(chat.isFailure, isTrue);
    expect(chat.failure?.kind, AiFailureKind.noConfiguration);
    final coffee = await ai.analyzeCoffee(
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
    );
    expect(coffee.failure?.kind, AiFailureKind.imageAnalysisUnavailable);
  });

  test('dream parser validates structure and rejects junk', () {
    final ok = DreamAnalysisParser.parse('''
{
  "ozet": "Rüyada ev ve yılan birlikte görünüyor.",
  "semboller": ["yılan", "ev"],
  "duygusalTema": "Huzursuz bir uyanış hissi var.",
  "yorum": "Sınırlar ve dönüşüm teması öne çıkıyor burada.",
  "gunlukYansi": "Bugün bir sınırı netleştirmek iyi gelebilir.",
  "sonuc": "Küçük bir adım yeter; acele etme."
}
''');
    expect(ok, isNotNull);
    expect(ok!.symbols, ['yılan', 'ev']);
    expect(DreamAnalysisParser.parse('{"ozet":"kısa"}'), isNull);
    expect(DreamAnalysisParser.parse('not json at all'), isNull);
  });

  test('coffee parser separates visual from symbols and invents none', () {
    final reading = CoffeeReadingParser.parse('''
{
  "gorselTespit": "Fincan tabanında ince bir çizgi ve sağda küçük bir boşluk.",
  "genelYorum": "Fincanda sakin bir açıklık var.",
  "ask": "Yakınlık için net bir cümle iyi gelir.",
  "kariyer": "Tek bir işi bitirmek kazandırır.",
  "maddiDurum": "Küçük bir birikim adımı yeter.",
  "yakinDonem": "Acele kararları bir gece beklet.",
  "semboller": [],
  "sonuc": "Bugün sakin ve net dur."
}
''', id: 'c-vis', createdAt: DateTime(2026, 8, 9));
    expect(reading, isNotNull);
    expect(reading!.visualObservation, contains('çizgi'));
    expect(reading.symbols, isEmpty);
    final analysis = CoffeeVisionParser.parse(
      '{"genelYorum":"ok","sonuc":"dur","semboller":[{"ad":"Kuş","anlam":"Haber","yorum":"Kapı."}]}',
    );
    expect(analysis, isNotNull);
    expect(analysis!.symbols.first.name, 'Kuş');
  });

  test('OR contexts stay isolated by kind', () {
    final tarot = OracleContextMapper.fromOracle(
      const OracleReadingContext(
        sessionId: 't1',
        kind: OracleReadingKind.tarot,
        spreadLabel: 'Üç Kart',
        deckId: 'rider-waite',
        deckName: 'Rider-Waite',
        readingTitle: 'Üç Kart',
        cardsSummary: 'The Moon',
        interpretationSummary: 'Net konuş.',
        cardNames: ['The Moon'],
      ),
    );
    final dream = OracleContextMapper.fromOracle(
      OracleReadingContextSources.dream(
        id: 'd1',
        narrative: 'Yılan evden geçti.',
        analysis: 'Dönüşüm teması.',
        symbols: const ['yılan'],
      ),
    );
    final coffee = OracleContextMapper.fromOracle(
      OracleReadingContextSources.coffee(
        CoffeeReading(
          id: 'c1',
          createdAt: DateTime(2026, 8, 9),
          overall: 'Duruluk.',
          love: 'Yakınlık.',
          career: 'Sabır.',
          money: 'Denge.',
          nearFuture: 'Yavaşla.',
          takeaway: 'Sakin kal.',
          visualObservation: 'İnce bir çizgi.',
        ),
      ),
    );
    expect(tarot.kindId, 'tarot');
    expect(dream.kindId, 'dream');
    expect(coffee.kindId, 'coffee');
    expect(tarot, isA<TarotAiContext>());
    expect(dream, isA<DreamAiContext>());
    expect((dream as DreamAiContext).narrative, contains('Yılan'));
    final coffeeCtx = coffee as CoffeeAiContext;
    expect(coffeeCtx.overall, contains('Duruluk'));
    expect(coffeeCtx.fullInterpretation, contains('Görülen:'));
    expect(coffeeCtx.fullInterpretation, isNot(contains('The Moon')));
  });

  test('status mapper and transport never expose raw provider errors', () async {
    expect(OpenAiStatusMapper.fromStatus(429).kind, AiFailureKind.rateLimit);
    expect(OpenAiStatusMapper.fromStatus(401).kind, AiFailureKind.unauthorized);
    expect(OpenAiStatusMapper.fromStatus(403).kind, AiFailureKind.unauthorized);
    expect(OpenAiStatusMapper.fromStatus(500).kind, AiFailureKind.providerError);
    final transport = OpenAiTransport(
      config: const AiRuntimeConfig(openAiKey: 'test-key'),
      client: MockClient((_) async => http.Response('{"error":"sk-leak"}', 429)),
    );
    final outcome = await transport.complete(
      messages: const [
        {'role': 'user', 'content': 'hi'},
      ],
    );
    expect(outcome.failure?.kind, AiFailureKind.rateLimit);
    expect(outcome.failure?.userMessage, isNot(contains('sk-leak')));
  });

  test('duplicate in-flight guard coalesces instead of double-calling', () async {
    final guard = AiRequestGuard();
    final gate = Completer<void>();
    var runs = 0;
    final first = guard.run('chat', () async {
      runs += 1;
      await gate.future;
      return 7;
    });
    final second = guard.run('chat', () async {
      runs += 1;
      return 9;
    });
    gate.complete();
    expect(await first, 7);
    expect(await second, 7);
    expect(runs, 1);
  });

  test('dream service stays local when AI is off and errors when live fails',
      () async {
    final local = DreamExperienceService(
      repository: _MemDreams(),
      ai: const UnconfiguredOraclyAiService(allowsLocalFallback: true),
    );
    final result = await local.analyze(narrative: 'Rüyamda uzun bir yılan evden geçti.');
    expect(result.dream.insights, isNotEmpty);
    expect(local.aiAvailable, isFalse);

    final failing = DreamExperienceService(
      repository: _MemDreams(),
      ai: _FailingAi(),
    );
    expect(failing.aiAvailable, isTrue);
    await expectLater(
      failing.analyze(narrative: 'Rüyamda uzun bir yılan evden geçti.'),
      throwsA(isA<AiRequestException>()),
    );
  });

  test('live service maps invalid JSON to invalidResponse', () async {
    const config = AiRuntimeConfig(openAiKey: 'test-key');
    final ai = OpenAiOraclyAiService(
      config: config,
      transport: DirectOpenAiTransport(
        config: config,
        client: MockClient(
          (_) async => http.Response(
            '{"choices":[{"message":{"content":"sadece düz metin, json yok"}}]}',
            200,
          ),
        ),
      ),
    );
    final dream = await ai.analyzeDream(
      const DreamAiContext(narrative: 'Rüyamda deniz vardı ve yürüdüm.'),
    );
    expect(dream.failure?.kind, AiFailureKind.invalidResponse);
  });
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

class _FailingAi implements OraclyAiService {
  @override
  bool get isConfigured => true;

  @override
  bool get visionAvailable => true;

  @override
  bool get allowsLocalFallback => false;

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      AiOutcome.failure(AiFailure.timeout());

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      AiOutcome.failure(AiFailure.timeout());

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) async =>
      AiOutcome.failure(AiFailure.timeout());

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) async =>
      AiOutcome.failure(AiFailure.timeout());

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) async =>
      AiOutcome.failure(AiFailure.timeout());
}
