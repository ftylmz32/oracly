/// Bounded quality retries — then honest fallback, never fabricated content.
library;

import '../copy/resilience_copy.dart';
import 'ai_output_quality_context.dart';
import 'ai_output_quality_gate.dart';
import 'ai_output_quality_kind.dart';
import 'ai_output_quality_logger.dart';

abstract final class AiOutputQualityRunner {
  AiOutputQualityRunner._();

  static const maxAttempts = 2;

  static Future<String> runText({
    required String operationId,
    required AiOutputQualityKind kind,
    required Future<String> Function(int attempt) generate,
    required String fallback,
    AiOutputQualityContext context = const AiOutputQualityContext(),
    String Function(String raw)? transform,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final raw = await generate(attempt);
      final polished = transform == null
          ? AiOutputQualityGate.polish(raw, kind: kind)
          : transform(raw);
      final check = AiOutputQualityGate.validate(
        polished,
        kind: kind,
        context: context,
      );
      if (check.isAcceptable && polished.trim().isNotEmpty) {
        return polished;
      }
      if (check.category != null) {
        AiOutputQualityLogger.logFailure(
          operationId: operationId,
          category: check.category!,
          attempt: attempt,
        );
      }
    }
    return fallback;
  }

  static String fallbackFor(AiOutputQualityKind kind) => switch (kind) {
        AiOutputQualityKind.companion ||
        AiOutputQualityKind.oracle =>
          ResilienceCopy.aiResponseUnavailable,
        AiOutputQualityKind.tarot => ResilienceCopy.interpretationFailed,
        AiOutputQualityKind.dream ||
        AiOutputQualityKind.coffee ||
        AiOutputQualityKind.palm =>
          ResilienceCopy.aiUnavailable,
        _ => ResilienceCopy.aiResponseUnavailable,
      };
}
