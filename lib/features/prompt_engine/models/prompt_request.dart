/// OR-1160 — Validated prompt ready for an AI provider.
library;

import 'prompt_context.dart';
import 'prompt_metadata.dart';

class PromptRequest {
  const PromptRequest({
    required this.system,
    required this.user,
    required this.context,
    required this.metadata,
    required this.resolvedVariables,
  });

  final String system;
  final String user;
  final PromptContext context;
  final PromptMetadata metadata;
  final Map<String, dynamic> resolvedVariables;

  int get totalLength => system.length + user.length;

  List<Map<String, String>> toMessages() => [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ];

  PromptRequest copyWith({
    PromptMetadata? metadata,
  }) {
    return PromptRequest(
      system: system,
      user: user,
      context: context,
      metadata: metadata ?? this.metadata,
      resolvedVariables: resolvedVariables,
    );
  }
}
