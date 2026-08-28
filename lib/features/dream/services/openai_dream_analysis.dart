/// Dream AI adapter — delegates to [OraclyAiService], no fake text.
library;

import '../../ai/domain/models/ai_message.dart';
import '../../ai/domain/models/oracle_response.dart';
import '../../ai/domain/models/prompts/dream_prompt.dart';
import '../../ai/domain/repositories/dream_ai_repository.dart';
import '../../ai/production/ai_failure.dart';
import '../../ai/production/ai_request_exception.dart';
import '../../ai/production/contexts/reading_ai_context.dart';
import '../../ai/production/oracly_ai_service.dart';

class OpenAiDreamAnalysis implements DreamAIRepository {
  OpenAiDreamAnalysis({required this._ai});

  final OraclyAiService _ai;

  @override
  bool get isAvailable => _ai.isConfigured;

  @override
  Future<OracleResponse> analyze(DreamPrompt prompt) async {
    if (!_ai.isConfigured) {
      throw AiRequestException(AiFailure.noConfiguration());
    }
    final outcome = await _ai.analyzeDream(
      DreamAiContext(
        narrative: prompt.dreamText,
        symbols: prompt.symbols,
        emotions: prompt.emotions,
      ),
    );
    return outcome.when(
      success: (analysis) {
        final text = [
          analysis.summary,
          analysis.interpretation,
          analysis.dailyLifeReflection,
          analysis.conclusion,
        ].join('\n\n');
        return OracleResponse(
          message: AIMessage(
            id: 'dream_${DateTime.now().millisecondsSinceEpoch}',
            role: AIMessageRole.assistant,
            content: text,
            createdAt: DateTime.now(),
          ),
          format: OracleResponseFormat.markdown,
          modelId: 'oracly-ai',
        );
      },
      error: (failure) => throw AiRequestException(failure),
    );
  }

  @override
  Stream<String> streamAnalysis(DreamPrompt prompt) async* {
    yield (await analyze(prompt)).text;
  }
}
