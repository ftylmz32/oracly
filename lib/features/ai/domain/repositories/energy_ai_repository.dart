/// OR-1110 — Daily energy AI repository interface.
library;

import '../models/oracle_response.dart';
import '../models/prompts/daily_energy_prompt.dart';

abstract class EnergyAIRepository {
  Future<OracleResponse> generateGuidance(DailyEnergyPrompt prompt);
  Stream<String> streamGuidance(DailyEnergyPrompt prompt);
}
