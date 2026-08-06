/// OR-1160 — Validates required and typed template variables.
library;

import '../models/prompt_template.dart';
import 'prompt_validation.dart';

class VariableValidator implements PromptValidator {
  const VariableValidator();

  @override
  PromptValidationResult validate({
    required PromptValidationContext context,
  }) {
    final template = context.template as PromptTemplate;
    final issues = <PromptValidationIssue>[];

    for (final variable in template.variables) {
      final value = context.variables[variable.key];
      final hasValue = value != null &&
          !(value is String && value.trim().isEmpty) &&
          !(value is Iterable && value.isEmpty);

      if (variable.required && !hasValue) {
        issues.add(
          PromptValidationIssue(
            code: 'missing_variable',
            message: 'Zorunlu değişken eksik: ${variable.key}',
            field: variable.key,
          ),
        );
        continue;
      }

      if (hasValue && !variable.validateValue(value)) {
        issues.add(
          PromptValidationIssue(
            code: 'invalid_variable',
            message: 'Geçersiz değer: ${variable.key}',
            field: variable.key,
          ),
        );
      }
    }

    return PromptValidationResult(issues: issues);
  }
}
