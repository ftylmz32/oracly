/// OR-1110 — Mock tarot AI repository.
library;

import '../../domain/models/oracle_response.dart';
import '../../domain/models/prompts/tarot_prompt.dart';
import '../../domain/repositories/tarot_ai_repository.dart';
import '../../services/openai_service.dart';
import '../../services/prompt_builder.dart';
import '../../services/response_parser.dart';
import '../mock/mock_ai_responses.dart';

class MockTarotAIRepository implements TarotAIRepository {
  MockTarotAIRepository({OpenAIService? openAI})
      : _openAI = openAI ?? MockOpenAIService();

  final OpenAIService _openAI;

  @override
  Future<OracleResponse> interpret(TarotPrompt prompt) async {
    final built = PromptBuilder.tarot(prompt);
    final response = await _openAI.complete(built);
    final enriched = MockAIResponses.tarotInterpretation(
      prompt.cardName,
      prompt.spreadType,
    );
    return ResponseParser.parse(
      rawText: enriched,
      messageId: response.message.id,
      tokenUsage: response.tokenUsage,
      latencyMs: response.latencyMs,
    );
  }

  @override
  Stream<String> streamInterpretation(TarotPrompt prompt) {
    return _openAI.stream(PromptBuilder.tarot(prompt));
  }
}
