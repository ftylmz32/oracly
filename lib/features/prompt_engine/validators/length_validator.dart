/// OR-1160 — Validates total prompt length limits.
library;

import '../models/prompt_template.dart';
import 'prompt_validation.dart';

class LengthValidator implements PromptValidator {
  const LengthValidator({this.hardLimit = 16000});

  final int hardLimit;

  @override
  PromptValidationResult validate({
    required PromptValidationContext context,
  }) {
    final template = context.template as PromptTemplate;
    final total = context.systemText.length + context.userText.length;
    final issues = <PromptValidationIssue>[];

    if (total > template.maxPromptLength) {
      issues.add(
        PromptValidationIssue(
          code: 'prompt_too_long',
          message:
              'Prompt uzunluğu ($total) şablon limitini (${template.maxPromptLength}) aşıyor.',
        ),
      );
    }

    if (total > hardLimit) {
      issues.add(
        PromptValidationIssue(
          code: 'prompt_hard_limit',
          message: 'Prompt mutlak limiti ($hardLimit) aşıyor.',
        ),
      );
    }

    if (context.systemText.trim().isEmpty) {
      issues.add(
        const PromptValidationIssue(
          code: 'empty_system',
          message: 'System prompt boş olamaz.',
        ),
      );
    }

    if (context.userText.trim().isEmpty) {
      issues.add(
        const PromptValidationIssue(
          code: 'empty_user',
          message: 'User prompt boş olamaz.',
        ),
      );
    }

    return PromptValidationResult(issues: issues);
  }
}
