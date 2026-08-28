/// DEV-only dream/coffee parsing for [DirectOpenAiTransport].
library;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../contexts/reading_ai_context.dart';
import '../openai/coffee_prompt_builder.dart';
import '../openai/coffee_vision_parser.dart';
import '../openai/dream_analysis_parser.dart';
import '../openai/dream_prompt_builder.dart';
import '../openai/openai_transport.dart';

abstract final class DirectOpenAiAnalysis {
  DirectOpenAiAnalysis._();

  static Future<AiOutcome<Map<String, dynamic>>> dream(
    OpenAiTransport openAi,
    Map<String, dynamic> payload,
  ) async {
    final outcome = await openAi.complete(
      messages: DreamPromptBuilder.messages(
        DreamAiContext(
          narrative: payload['narrative'] as String? ?? '',
          symbols: strings(payload['symbols']),
          emotions: strings(payload['emotions']),
        ),
      ),
    );
    return outcome.when(
      success: (text) {
        final parsed = DreamAnalysisParser.parse(text);
        if (parsed == null) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(DreamAnalysisParser.toMap(parsed));
      },
      error: AiOutcome.failure,
    );
  }

  static Future<AiOutcome<Map<String, dynamic>>> coffee(
    OpenAiTransport openAi,
    Map<String, dynamic> payload,
  ) async {
    final mime = payload['mimeType'] as String? ?? '';
    final b64 = payload['imageBase64'] as String? ?? '';
    if (b64.isEmpty) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final outcome = await openAi.complete(
      messages: CoffeePromptBuilder.messages(base64: b64, mimeType: mime),
    );
    return outcome.when(
      success: (text) {
        final parsed = CoffeeVisionParser.parse(text);
        if (parsed == null) {
          return AiOutcome.failure(AiFailure.invalidResponse());
        }
        return AiOutcome.success(CoffeeVisionParser.toMap(parsed));
      },
      error: AiOutcome.failure,
    );
  }

  static List<String> strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
