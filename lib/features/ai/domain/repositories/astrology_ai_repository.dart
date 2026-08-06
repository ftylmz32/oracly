/// OR-1110 — Astrology AI repository interface.
library;

import '../models/oracle_response.dart';
import '../models/prompts/astrology_prompt.dart';

abstract class AstrologyAIRepository {
  Future<OracleResponse> consult(AstrologyPrompt prompt);
  Stream<String> streamConsultation(AstrologyPrompt prompt);
}
