/// OR-1160 — Composite prompt validation pipeline.
library;

import 'format_validator.dart';
import 'length_validator.dart';
import 'prompt_validation.dart';
import 'variable_validator.dart';

class PromptValidatorPipeline {
  PromptValidatorPipeline({
    List<PromptValidator>? validators,
  }) : _validators = validators ??
            const [
              VariableValidator(),
              LengthValidator(),
              FormatValidator(),
            ];

  final List<PromptValidator> _validators;

  PromptValidationResult validate(PromptValidationContext context) {
    final allIssues = <PromptValidationIssue>[];
    for (final validator in _validators) {
      allIssues.addAll(validator.validate(context: context).issues);
    }
    return PromptValidationResult(issues: allIssues);
  }
}

class PromptValidationException implements Exception {
  PromptValidationException(this.result);
  final PromptValidationResult result;

  @override
  String toString() =>
      'Prompt validation failed: ${result.errors.map((e) => e.message).join('; ')}';
}
