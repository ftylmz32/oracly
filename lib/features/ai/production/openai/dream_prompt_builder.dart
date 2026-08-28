/// Dream analysis prompt — structured JSON only, no invented symbols.
library;

import '../../../ai/services/prompt_sanitizer.dart';
import '../contexts/reading_ai_context.dart';
import 'dream_prompt_style.dart';

abstract final class DreamPromptBuilder {
  DreamPromptBuilder._();

  static const system = DreamPromptStyle.system;

  static List<Map<String, dynamic>> messages(DreamAiContext context) {
    final extras = [
      if (context.symbols.isNotEmpty)
        'Gözlenen semboller: ${context.symbols.join(', ')}',
      if (context.emotions.isNotEmpty)
        'Belirtilen duygular: ${context.emotions.join(', ')}',
    ].join('\n');
    final narrative = PromptSanitizer.sanitize(context.narrative);
    return [
      {'role': 'system', 'content': system},
      {
        'role': 'user',
        'content':
            '${DreamPromptStyle.userLead}\n\n'
            '$narrative${extras.isEmpty ? '' : '\n\n$extras'}',
      },
    ];
  }
}
