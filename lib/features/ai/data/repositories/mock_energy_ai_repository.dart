/// OR-1110 — Mock daily energy AI repository.
library;

import '../../domain/models/oracle_response.dart';
import '../../domain/models/prompts/daily_energy_prompt.dart';
import '../../domain/repositories/energy_ai_repository.dart';
import '../../services/openai_service.dart';
import '../../services/prompt_builder.dart';
import '../../services/response_parser.dart';
import '../mock/mock_ai_responses.dart';

class MockEnergyAIRepository implements EnergyAIRepository {
  MockEnergyAIRepository({OpenAIService? openAI})
      : _openAI = openAI ?? MockOpenAIService();

  final OpenAIService _openAI;

  @override
  Future<OracleResponse> generateGuidance(DailyEnergyPrompt prompt) async {
    await _openAI.complete(PromptBuilder.dailyEnergy(prompt));
    return ResponseParser.parse(
      rawText: MockAIResponses.dailyEnergyGuidance(
        prompt.energyLevel,
        prompt.moodLabel,
      ),
      messageId: 'energy_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Stream<String> streamGuidance(DailyEnergyPrompt prompt) {
    return _openAI.stream(PromptBuilder.dailyEnergy(prompt));
  }
}
