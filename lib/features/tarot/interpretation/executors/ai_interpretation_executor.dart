/// Production Tarot executor through the shared Oracly AI proxy.
library;

import '../../../ai/production/ai_failure.dart';
import '../../../ai/production/models/tarot_ai_analysis.dart';
import '../../../ai/production/oracly_ai_service.dart';
import '../models/interpretation_error.dart';
import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';
import 'interpretation_executor.dart';

/// Sends only current-card evidence plus separately tagged continuity metadata.
/// A production failure is thrown so [TarotInterpretationService] can own the
/// retry/fallback policy without ever mislabelling local copy as AI.
class AiInterpretationExecutor implements InterpretationExecutor {
  AiInterpretationExecutor({required OraclyAiService ai}) : _ai = ai;

  final OraclyAiService _ai;

  @override
  bool get isOnline => _ai.isConfigured;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    final context = request.context;
    final hints = context.journeyHints;
    final outcome = await _ai.analyzeTarot(
      TarotAiRequestContext(
        sessionId: context.sessionId,
        spreadLabel: context.spreadLabel,
        userQuestion: context.userQuestion,
        readingTheme: context.readingTheme,
        cards: [
          for (final card in context.cards)
            TarotAiCardEvidence(
              cardId: card.cardId,
              cardName: card.cardName,
              positionLabel: card.positionLabel,
              positionKey: card.positionKey,
              isReversed: card.isReversed,
              meaning: card.effectiveMeaning,
              keywords: card.keywords,
            ),
        ],
        continuity: hints == null
            ? const TarotAiContinuity()
            : TarotAiContinuity(
                recurringThemes: hints.recurringThemeLabels.take(4).toList(),
                recentCardNames: hints.recentCardNames.take(3).toList(),
                hasPriorNotes: hints.hasPriorNotes,
                priorReadingCount: hints.priorReadingCount,
                revisitPriorExcerpt: hints.revisitPriorExcerpt,
                revisitInstruction: hints.revisitInstruction,
              ),
      ),
    );

    return outcome.when(
      success: (analysis) => InterpretationResult(
        requestId: request.requestId,
        sessionId: context.sessionId,
        summary: analysis.summary,
        love: analysis.love,
        career: analysis.career,
        money: analysis.money,
        health: analysis.health,
        spiritualGuidance: analysis.spiritualGuidance,
        advice: analysis.advice,
        warnings: analysis.warnings,
        luckyEnergy: analysis.luckyEnergy,
        dailyFocus: analysis.dailyFocus,
        closingMessage: analysis.closingMessage,
        generatedAt: DateTime.now(),
        source: InterpretationSource.ai,
        rawText: analysis.rawText,
      ),
      error: _throwFailure,
    );
  }

  Never _throwFailure(AiFailure failure) {
    final type = switch (failure.kind) {
      AiFailureKind.timeout => InterpretationFailureType.timeout,
      AiFailureKind.network ||
      AiFailureKind.noConfiguration ||
      AiFailureKind.unauthorized ||
      AiFailureKind.authPending ||
      AiFailureKind.appCheck ||
      AiFailureKind.providerError ||
      AiFailureKind.rateLimit ||
      AiFailureKind.imageAnalysisUnavailable ||
      AiFailureKind.localPersistence => InterpretationFailureType.retry,
      AiFailureKind.invalidResponse => InterpretationFailureType.invalidResponse,
    };
    throw InterpretationException(
      type: type,
      message: failure.userMessage,
      cause: failure,
      retryable: failure.kind != AiFailureKind.invalidResponse,
    );
  }

  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) async* {
    yield const InterpretationStreamEvent(
      phase: InterpretationStreamPhase.started,
      progress: 0,
    );
    final result = await execute(request);
    yield InterpretationStreamEvent(
      phase: InterpretationStreamPhase.completed,
      result: result,
      progress: 1,
    );
  }
}
