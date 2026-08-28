/// Honest dream AI port when no live model is configured.
library;

import '../../ai/domain/models/oracle_response.dart';
import '../../ai/domain/models/prompts/dream_prompt.dart';
import '../../ai/domain/repositories/dream_ai_repository.dart';

class UnavailableDreamAI implements DreamAIRepository {
  const UnavailableDreamAI();

  @override
  bool get isAvailable => false;

  @override
  Future<OracleResponse> analyze(DreamPrompt prompt) {
    throw StateError('Dream AI is not configured.');
  }

  @override
  Stream<String> streamAnalysis(DreamPrompt prompt) {
    throw StateError('Dream AI is not configured.');
  }
}
