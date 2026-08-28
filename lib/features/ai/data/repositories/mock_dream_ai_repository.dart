/// OR-1110 — Mock dream AI repository.
library;

import '../../domain/models/oracle_response.dart';
import '../../domain/models/prompts/dream_prompt.dart';
import '../../domain/repositories/dream_ai_repository.dart';
import '../../services/openai_service.dart';
import '../../services/prompt_builder.dart';
import '../../services/response_parser.dart';
import '../mock/mock_ai_responses.dart';

class MockDreamAIRepository implements DreamAIRepository {
  MockDreamAIRepository({OpenAIService? openAI})
      : _openAI = openAI ?? MockOpenAIService();

  final OpenAIService _openAI;

  @override
  bool get isAvailable => false;

  @override
  Future<OracleResponse> analyze(DreamPrompt prompt) async {
    await _openAI.complete(PromptBuilder.dream(prompt));
    final excerpt = prompt.dreamText.length > 40
        ? '${prompt.dreamText.substring(0, 40)}...'
        : prompt.dreamText;
    return ResponseParser.parse(
      rawText: MockAIResponses.dreamAnalysis(excerpt),
      messageId: 'dream_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Stream<String> streamAnalysis(DreamPrompt prompt) {
    return _openAI.stream(PromptBuilder.dream(prompt));
  }
}
