/// OR response pipeline — one finalize, honest fromAi, no leak into body.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/ai_source_copy.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/core/reading/ai_output_quality_runner.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/companion/services/or_response_finalize.dart';

void main() {
  test('transport chat parses only — keeps provider text intact', () {
    final outcome = OpenAiServiceResults.chat(
      AiOutcome.success(const {
        'text': 'Kesin yarın her şey düzelecek ve mutlu olacaksın.',
      }),
      'test-model',
    );
    final text = outcome.when(
      success: (reply) => reply.text,
      error: (_) => '',
    );
    expect(text, contains('Kesin'));
  });

  test('transport rejects broken envelopes', () {
    final outcome = OpenAiServiceResults.chat(
      AiOutcome.success(const {'text': '```json\n{"a":1}\n```'}),
      'test-model',
    );
    expect(
      outcome.when(success: (_) => false, error: (_) => true),
      isTrue,
    );
  });

  test('finalize strips source/debug leak lines from body', () {
    final cleaned = OrResponseFinalize.stripInternalLeak(
      '[OR] bridge stage=localFallback\n'
      'Yerel yansıma — canlı yapay zekâ değil.\n'
      'Burada sakin duruyoruz.\n'
      'debug: provider=proxy',
    );
    expect(cleaned, contains('Burada sakin duruyoruz'));
    expect(cleaned.toLowerCase(), isNot(contains('yerel yansıma')));
    expect(cleaned, isNot(contains('[OR]')));
    expect(cleaned.toLowerCase(), isNot(contains('debug:')));
  });

  test('live quality fallback is never returned as companion text', () async {
    final fallback =
        AiOutputQualityRunner.fallbackFor(AiOutputQualityKind.companion);
    final bridge = CompanionAiBridge(_FixedAi(fallback));
    await expectLater(
      bridge.tryLive(userMessage: 'Selam'),
      throwsA(
        isA<AiRequestException>().having(
          (e) => e.failure.kind,
          'kind',
          AiFailureKind.invalidResponse,
        ),
      ),
    );
    expect(fallback, ResilienceCopy.aiResponseUnavailable);
  });

  test('local fallback path is never tagged live by AiSourceCopy', () {
    expect(AiSourceCopy.tag(fromAi: false)['source'], AiSourceCopy.metaLocal);
    expect(AiSourceCopy.tag(fromAi: true)['source'], AiSourceCopy.metaLive);
  });

  test('unconfigured bridge yields null for local path, not fake live',
      () async {
    final text = await CompanionAiBridge(
      const UnconfiguredOraclyAiService(allowsLocalFallback: true),
    ).tryLiveOrFailClosed(userMessage: 'Merhaba');
    expect(text, isNull);
  });

  test('finalize apply keeps conversational body', () {
    final out = OrResponseFinalize.apply(
      'Karar eşiğinde duruyorsun. Bir adım yeter.',
      userMessage: 'Karar vermekte zorlanıyorum biraz.',
      depth: OrResponseDepth.balanced,
    );
    expect(out.trim(), isNotEmpty);
    expect(out.toLowerCase(), isNot(contains('yerel yansıma')));
  });
}

class _FixedAi implements OraclyAiService {
  _FixedAi(this.text);
  final String text;

  @override
  bool get isConfigured => true;

  @override
  bool get allowsLocalFallback => false;

  @override
  bool get visionAvailable => false;

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
      AiOutcome.success(ChatAiReply(text: text));

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
  }) {
    throw UnsupportedError('oracle');
  }

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    throw UnsupportedError('dream');
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) {
    throw UnsupportedError('coffee');
  }

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) {
    throw UnsupportedError('palm');
  }
}
