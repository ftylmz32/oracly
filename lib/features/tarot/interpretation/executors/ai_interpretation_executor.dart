/// Real backend-proxied Tarot AI executor — grounded strictly in the drawn
/// cards. Never calls OpenAI directly from the client (proxy-only, matching
/// every other paid AI feature). Throws on any failure so the caller
/// (TarotInterpretationService) falls back to LocalInterpretationExecutor —
/// AI is the primary path, local synthesis is the fail-closed fallback.
library;

import '../../../ai/production/oracly_ai_service.dart';
import '../formatters/interpretation_formatter.dart';
import '../models/interpretation_error.dart';
import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';
import '../models/reading_context.dart';
import 'interpretation_executor.dart';
import 'local_interpretation_executor.dart';

class AiInterpretationExecutor implements InterpretationExecutor {
  AiInterpretationExecutor({
    required OraclyAiService ai,
    InterpretationFormatter? formatter,
    LocalInterpretationExecutor? fallback,
  }) : _ai = ai,
       _formatter = formatter ?? const InterpretationFormatter(),
       _fallback = fallback ?? LocalInterpretationExecutor();

  final OraclyAiService _ai;
  final InterpretationFormatter _formatter;
  final LocalInterpretationExecutor _fallback;

  @override
  bool get isOnline => true;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    final outcome = await _ai.generateTarotReading(
      cards: _cardsPayload(request.context),
      spreadLabel: request.context.spreadLabel,
      userQuestion: request.context.userQuestion,
      readingTheme: request.context.readingTheme,
      journeyHints: _journeyHintsPayload(request.context),
    );
    return outcome.when(
      success: (reply) => parseAiResponse(request, reply.text),
      error: (failure) => throw InterpretationException(
        type: InterpretationFailureType.retry,
        message: failure.userMessage,
        retryable: true,
      ),
    );
  }

  /// Streaming isn't wired to a real token stream yet — local synthesis
  /// (already instant) covers that mode safely.
  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) => _fallback.executeStream(request);

  InterpretationResult parseAiResponse(
    InterpretationRequest request,
    String rawText,
  ) {
    final parsed = _formatter.parseRawResponse(
      rawText: rawText,
      requestId: request.requestId,
      sessionId: request.context.sessionId,
      source: InterpretationSource.ai,
    );
    if (parsed == null) {
      throw const InterpretationException(
        type: InterpretationFailureType.emptyResponse,
        message: 'AI yanıtı boş.',
      );
    }
    if (!_formatter.validate(parsed)) {
      throw const InterpretationException(
        type: InterpretationFailureType.invalidResponse,
        message: 'AI yanıtı geçerli bölümler içermiyor.',
      );
    }
    return parsed;
  }

  static List<Map<String, dynamic>> _cardsPayload(ReadingContext context) {
    return [
      for (final card in context.cards)
        {
          'name': card.cardName,
          'positionLabel': card.positionLabel,
          'reversed': card.isReversed,
          'meaning': card.effectiveMeaning,
          'keywords': card.keywords,
        },
    ];
  }

  static Map<String, dynamic>? _journeyHintsPayload(ReadingContext context) {
    final hints = context.journeyHints;
    if (hints == null || hints.isEmpty) return null;
    return {
      'recurringThemes': hints.recurringThemeLabels,
      'recentCardNames': hints.recentCardNames,
      'priorReadingCount': hints.priorReadingCount,
      if (hints.revisitPriorExcerpt != null &&
          hints.revisitPriorExcerpt!.trim().isNotEmpty)
        'revisitExcerpt': hints.revisitPriorExcerpt,
      if (hints.memorySummary != null && hints.memorySummary!.trim().isNotEmpty)
        'memorySummary': hints.memorySummary,
    };
  }
}
