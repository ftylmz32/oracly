/// OR-1160 — Validates rendered template formatting.
library;

import 'prompt_validation.dart';

class FormatValidator implements PromptValidator {
  const FormatValidator();

  static final _unresolvedPattern = RegExp(r'\{\{[^}]+\}\}');

  @override
  PromptValidationResult validate({
    required PromptValidationContext context,
  }) {
    final issues = <PromptValidationIssue>[];

    for (final text in [context.systemText, context.userText]) {
      final matches = _unresolvedPattern.allMatches(text);
      for (final match in matches) {
        issues.add(
          PromptValidationIssue(
            code: 'unresolved_placeholder',
            message: 'Çözülmemiş şablon ifadesi: ${match.group(0)}',
            severity: PromptValidationSeverity.warning,
          ),
        );
      }

      if (text.contains('{{') && text.contains('}}')) {
        final openCount = '{{'.allMatches(text).length;
        final closeCount = '}}'.allMatches(text).length;
        if (openCount != closeCount) {
          issues.add(
            const PromptValidationIssue(
              code: 'malformed_template',
              message: 'Şablon blokları dengesiz görünüyor.',
              severity: PromptValidationSeverity.warning,
            ),
          );
        }
      }
    }

    return PromptValidationResult(issues: issues);
  }
}
