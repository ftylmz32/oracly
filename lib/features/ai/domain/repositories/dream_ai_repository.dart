/// OR-1110 — Dream AI repository interface.
library;

import '../models/oracle_response.dart';
import '../models/prompts/dream_prompt.dart';

abstract class DreamAIRepository {
  Future<OracleResponse> analyze(DreamPrompt prompt);
  Stream<String> streamAnalysis(DreamPrompt prompt);
}
