/// Production-safe Tarot executor selection from AI runtime policy.
library;

import '../../ai/production/oracly_ai_service.dart';
import '../interpretation/executors/ai_interpretation_executor.dart';
import '../interpretation/executors/interpretation_executor.dart';
import '../interpretation/executors/local_interpretation_executor.dart';

/// Local synthesis only when [OraclyAiService.allowsLocalFallback] is true.
/// Narrative V2 routing lives in [TarotInterpretationService], not here.
InterpretationExecutor tarotInterpretationExecutorFor(OraclyAiService ai) {
  if (!ai.isConfigured && ai.allowsLocalFallback) {
    return LocalInterpretationExecutor();
  }
  return AiInterpretationExecutor(ai: ai);
}
