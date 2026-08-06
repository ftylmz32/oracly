/// OR-1110 — Tarot AI repository interface.
library;

import '../models/oracle_response.dart';
import '../models/prompts/tarot_prompt.dart';

abstract class TarotAIRepository {
  Future<OracleResponse> interpret(TarotPrompt prompt);
  Stream<String> streamInterpretation(TarotPrompt prompt);
}
