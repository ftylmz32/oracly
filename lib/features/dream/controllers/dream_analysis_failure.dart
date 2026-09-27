/// Dream failure → calm user copy; logs metadata only, never content.
library;

import '../../../core/logging/analysis_debug_log.dart';
import '../../ai/production/ai_request_exception.dart';
import '../copy/dream_copy.dart';

abstract final class DreamAnalysisFailure {
  DreamAnalysisFailure._();

  static String messageFor(String stage, Object error) {
    if (error is AiRequestException) {
      logAnalysisFailure(
        feature: 'DreamAnalysis',
        stage: stage,
        kind: error.failure.kind.name,
      );
      return error.userMessage;
    }
    logAnalysisFailure(feature: 'DreamAnalysis', stage: stage, error: error);
    return DreamCopy.analysisFailed;
  }
}
