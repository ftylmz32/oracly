/// OR-1160 — Structured AI response envelope.
library;

import '../formatters/output_format.dart';
import 'prompt_metadata.dart';

class PromptResponse {
  const PromptResponse({
    required this.rawText,
    required this.metadata,
    this.structured,
    this.finishReason,
  });

  final String rawText;
  final PromptMetadata metadata;
  final StructuredPromptOutput? structured;
  final String? finishReason;

  PromptResponse copyWith({
    StructuredPromptOutput? structured,
    String? finishReason,
  }) {
    return PromptResponse(
      rawText: rawText,
      metadata: metadata,
      structured: structured ?? this.structured,
      finishReason: finishReason ?? this.finishReason,
    );
  }
}
