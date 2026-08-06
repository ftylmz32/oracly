/// OR-1180 — Future OpenAI executor stub (no network calls).
library;

import '../formatters/interpretation_formatter.dart';
import '../models/interpretation_error.dart';
import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';
import 'interpretation_executor.dart';
import 'local_interpretation_executor.dart';

/// AI executor placeholder — validates prompt readiness and delegates to local
/// synthesis until OpenAI transport is wired.
class AiInterpretationExecutor implements InterpretationExecutor {
  AiInterpretationExecutor({
    InterpretationFormatter? formatter,
    LocalInterpretationExecutor? fallback,
  })  : _formatter = formatter ?? const InterpretationFormatter(),
        _fallback = fallback ?? LocalInterpretationExecutor();

  final InterpretationFormatter _formatter;
  final LocalInterpretationExecutor _fallback;

  @override
  bool get isOnline => false;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) async {
    if (request.promptRequest == null) {
      throw const InterpretationException(
        type: InterpretationFailureType.invalidResponse,
        message: 'PromptRequest eksik — PromptEngine entegrasyonu gerekli.',
        retryable: false,
      );
    }

    // Future: send request.promptRequest!.toMessages() to OpenAI transport.
    // For OR-1180 we produce AI-ready structured output via content synthesis.
    final local = await _fallback.execute(request);
    return local.copyWith(
      source: InterpretationSource.ai,
      rawText: request.promptRequest!.toMessages().toString(),
    );
  }

  @override
  Stream<InterpretationStreamEvent> executeStream(
    InterpretationRequest request,
  ) =>
      _fallback.executeStream(request);

  InterpretationResult? parseAiResponse(
    InterpretationRequest request,
    String rawText,
  ) {
    final parsed = _formatter.parseRawResponse(
      rawText: rawText,
      requestId: request.requestId,
      sessionId: request.context.sessionId,
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
}
