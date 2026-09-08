/// Optional Tarot capability for AI services that support structured Tarot analysis.
library;

import 'ai_outcome.dart';
import 'models/tarot_ai_analysis.dart';

abstract class TarotAiService {
  Future<AiOutcome<TarotAiAnalysis>> analyzeTarot(
    TarotAiRequestContext context,
  );
}
