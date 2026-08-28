/// DEV-only direct OpenAI. Forbidden in production/staging/release builds.
library;

import 'package:http/http.dart' as http;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../ai_runtime_config.dart';
import '../models/conversation_turn.dart';
import '../openai/chat_prompt_builder.dart';
import '../../../../core/personality/or_response_depth.dart';
import '../openai/openai_transport.dart';
import '../openai/oracle_prompt_builder.dart';
import 'ai_operation.dart';
import 'ai_proxy_request.dart';
import 'ai_transport.dart';
import 'direct_openai_analysis.dart';
import 'reading_context_from_json.dart';

class DirectOpenAiTransport implements AiTransport {
  DirectOpenAiTransport({
    required AiRuntimeConfig config,
    http.Client? client,
    OpenAiTransport? openAi,
  })  : _config = config,
        _openAi = openAi ?? OpenAiTransport(config: config, client: client);

  final AiRuntimeConfig _config;
  final OpenAiTransport _openAi;

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(AiProxyRequest request) {
    if (!_config.usesClientKey) {
      return Future.value(AiOutcome.failure(AiFailure.noConfiguration()));
    }
    final payload = request.payload;
    return switch (request.operation) {
      AiOperation.chat => _chat(payload),
      AiOperation.oracle => _oracle(payload),
      AiOperation.dreamAnalysis => DirectOpenAiAnalysis.dream(_openAi, payload),
      AiOperation.coffeeAnalysis =>
        DirectOpenAiAnalysis.coffee(_openAi, payload),
      AiOperation.palmAnalysis => Future.value(
          AiOutcome.failure(AiFailure.imageAnalysisUnavailable()),
        ),
      AiOperation.soulmateDraw => Future.value(
          AiOutcome.failure(AiFailure.noConfiguration()),
        ),
      AiOperation.tts => _openAi.speech(
          text: payload['text'] as String? ?? '',
          personality: payload['personality'] as String? ?? 'mystical',
          language: payload['language'] as String? ?? 'tr',
          voiceId: payload['voiceId'] as String?,
          speechSpeed: payload['speechSpeed'] as String?,
        ),
    };
  }

  Future<AiOutcome<Map<String, dynamic>>> _chat(
    Map<String, dynamic> payload,
  ) async {
    final outcome = await _openAi.complete(
      messages: ChatPromptBuilder.messages(
        userMessage: payload['userMessage'] as String? ?? '',
        priorUser: DirectOpenAiAnalysis.strings(payload['priorUser']),
        styleHint: payload['styleHint'] as String?,
        personality: payload['personality'] as String?,
        turns: ConversationTurn.parseList(payload['turns']),
        depth: OrResponseDepth.parse(payload['depth'] as String?),
        spoken: payload['spoken'] == true,
      ),
    );
    return _textMap(outcome);
  }

  Future<AiOutcome<Map<String, dynamic>>> _oracle(
    Map<String, dynamic> payload,
  ) async {
    final raw = payload['context'];
    if (raw is! Map<String, dynamic>) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final context = ReadingContextFromJson.parse(raw);
    if (context == null) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final outcome = await _openAi.complete(
      messages: OraclePromptBuilder.messages(
        context: context,
        userMessage: payload['userMessage'] as String? ?? '',
        priorUser: DirectOpenAiAnalysis.strings(payload['priorUser']),
        turns: ConversationTurn.parseList(payload['turns']),
        styleHint: payload['styleHint'] as String?,
        personality: payload['personality'] as String?,
        depth: OrResponseDepth.parse(payload['depth'] as String?),
        spoken: payload['spoken'] == true,
      ),
    );
    return _textMap(outcome);
  }

  static AiOutcome<Map<String, dynamic>> _textMap(AiOutcome<String> outcome) {
    return outcome.when(
      success: (text) => AiOutcome.success({'text': text}),
      error: AiOutcome.failure,
    );
  }
}
