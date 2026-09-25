/// Phase 6F.1 — explicit max-two Narrative quality budget (no nested retry).
library;

import '../../../core/reading/ai_output_quality_logger.dart';
import '../../../core/reading/ai_output_quality_tarot.dart';
import '../../insights/services/reflective_intelligence.dart';
import '../domain/models/reading_session.dart';
import '../interpretation/formatters/interpretation_formatter.dart';
import '../interpretation/models/interpretation_error.dart';
import '../interpretation/models/interpretation_result.dart';
import '../interpretation/models/reading_context.dart';
import '../narrative/live/narrative_tarot_attempt.dart';
import '../narrative/live/narrative_tarot_live_interpreter.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';

typedef NarrativeFallback =
    Future<AiReadingContent> Function({required Object cause});

/// One state machine: attempt 1 → optional attempt 2 → fallback once.
abstract final class TarotNarrativeQualityBudget {
  TarotNarrativeQualityBudget._();

  static Future<AiReadingContent> generateContent({
    required NarrativeTarotLiveInterpreter narrative,
    required ReadingSession session,
    required ReadingContext context,
    required InterpretationFormatter formatter,
    required NarrativeFallback fallbackOrFail,
    bool forceRefresh = false,
  }) async {
    Object? lastCause;
    for (var attempt = 1; attempt <= kMaxNarrativeProviderAttempts; attempt++) {
      try {
        final candidate = await narrative.interpret(
          session: session,
          languageCode: context.language,
          forceRefresh: forceRefresh || attempt > 1,
          attempt: attempt,
        );
        final guarded = ReflectiveIntelligence.guard(candidate.result);
        if (!AiOutputQualityTarot.passes(guarded)) {
          lastCause = 'quality';
          final category = AiOutputQualityTarot.firstFailure(guarded);
          if (category != null) {
            AiOutputQualityLogger.logFailure(
              operationId: 'tarot.interpret.narrative',
              category: category,
              attempt: attempt,
            );
          }
          if (candidate.fromCache) {
            await narrative.invalidateKey(candidate.cacheKey);
          }
          if (attempt < kMaxNarrativeProviderAttempts) continue;
          return fallbackOrFail(cause: lastCause);
        }
        await narrative.commitValidated(candidate, guarded);
        return formatter.toUiContent(result: guarded, session: session);
      } on InterpretationException catch (e) {
        lastCause = e;
        if (attempt < kMaxNarrativeProviderAttempts && e.retryable) {
          continue;
        }
        return fallbackOrFail(cause: e);
      } catch (e) {
        // Invariant / unexpected — fail closed (no attempt 2).
        return fallbackOrFail(cause: e);
      }
    }
    return fallbackOrFail(cause: lastCause ?? 'narrative_exhausted');
  }

  static Future<InterpretationResult> generateResult({
    required NarrativeTarotLiveInterpreter narrative,
    required ReadingSession session,
    required ReadingContext context,
    bool forceRefresh = false,
  }) async {
    Object? lastCause;
    for (var attempt = 1; attempt <= kMaxNarrativeProviderAttempts; attempt++) {
      try {
        final candidate = await narrative.interpret(
          session: session,
          languageCode: context.language,
          forceRefresh: forceRefresh || attempt > 1,
          attempt: attempt,
        );
        final guarded = ReflectiveIntelligence.guard(candidate.result);
        if (!AiOutputQualityTarot.passes(guarded)) {
          lastCause = 'quality';
          if (candidate.fromCache) {
            await narrative.invalidateKey(candidate.cacheKey);
          }
          if (attempt < kMaxNarrativeProviderAttempts) continue;
          throw InterpretationException(
            type: InterpretationFailureType.invalidResponse,
            message: 'Narrative result failed final quality.',
            cause: lastCause,
            retryable: false,
          );
        }
        await narrative.commitValidated(candidate, guarded);
        return guarded;
      } on InterpretationException catch (e) {
        lastCause = e;
        if (attempt < kMaxNarrativeProviderAttempts && e.retryable) {
          continue;
        }
        rethrow;
      }
    }
    throw InterpretationException(
      type: InterpretationFailureType.retry,
      message: 'Narrative attempts exhausted.',
      cause: lastCause,
      retryable: false,
    );
  }
}
