/// OR-1110 — Mock astrology AI repository.
library;

import '../../domain/models/oracle_response.dart';
import '../../domain/models/prompts/astrology_prompt.dart';
import '../../domain/repositories/astrology_ai_repository.dart';
import '../../services/openai_service.dart';
import '../../services/prompt_builder.dart';
import '../../services/response_parser.dart';
import '../mock/mock_ai_responses.dart';

class MockAstrologyAIRepository implements AstrologyAIRepository {
  MockAstrologyAIRepository({OpenAIService? openAI})
      : _openAI = openAI ?? MockOpenAIService();

  final OpenAIService _openAI;

  @override
  Future<OracleResponse> consult(AstrologyPrompt prompt) async {
    await _openAI.complete(PromptBuilder.astrology(prompt));
    return ResponseParser.parse(
      rawText: MockAIResponses.astrologyReading(
        prompt.zodiacSign,
        prompt.question,
      ),
      messageId: 'astro_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Stream<String> streamConsultation(AstrologyPrompt prompt) {
    return _openAI.stream(PromptBuilder.astrology(prompt));
  }
}
