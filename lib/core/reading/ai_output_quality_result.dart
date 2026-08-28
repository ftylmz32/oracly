/// Pass/fail result from the quality gate.
library;

import 'ai_output_quality_category.dart';

class AiOutputQualityResult {
  const AiOutputQualityResult.pass()
      : isAcceptable = true,
        category = null;

  const AiOutputQualityResult.fail(AiOutputQualityCategory reason)
      : isAcceptable = false,
        category = reason;

  final bool isAcceptable;
  final AiOutputQualityCategory? category;
}
