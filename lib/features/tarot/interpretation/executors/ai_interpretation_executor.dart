/// OR-1180 — Future OpenAI executor stub (no network calls).
library;

import '../formatters/interpretation_formatter.dart';
import '../models/interpretation_error.dart';
import '../models/interpretation_request.dart';
import '../models/interpretation_result.dart';
import '../models/interpretation_stream_event.dart';
import 'interpretation_executor.dart';
import 'local_interpretation_executor.dart';

/// AI executor stub — no network. Local synthesis is never labeled AI.
class AiInterpretationExecutor implements InterpretationExecutor {
  AiInterpretationExecutor({
    InterpretationFormatter? formatter,
    LocalInterpretationExecutor? fallback,
  })  : _formatter = formatter ?? const InterpretationFormatter(),
        _fallback = fallback ?? LocalInterpretationExecutor();

  final InterpretationFormatter _formatter;
  final LocalInterpretationExecutor _fallback;

  @override
  bool get isOnline => true;

  @override
  Future<InterpretationResult> execute(InterpretationRequest request) {
    // Future: send request.promptRequest to OpenAI transport.
    // Until a real AI response exists, catalogue text stays local.
    return _fallback.execute(request);
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
}
