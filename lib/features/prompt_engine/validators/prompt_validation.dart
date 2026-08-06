/// OR-1160 — Validation issue descriptor.
library;

enum PromptValidationSeverity { error, warning }

class PromptValidationIssue {
  const PromptValidationIssue({
    required this.code,
    required this.message,
    this.severity = PromptValidationSeverity.error,
    this.field,
  });

  final String code;
  final String message;
  final PromptValidationSeverity severity;
  final String? field;
}

class PromptValidationResult {
  const PromptValidationResult({
    this.issues = const [],
  });

  final List<PromptValidationIssue> issues;

  bool get isValid => !issues.any(
        (i) => i.severity == PromptValidationSeverity.error,
      );

  List<PromptValidationIssue> get errors => issues
      .where((i) => i.severity == PromptValidationSeverity.error)
      .toList();

  List<PromptValidationIssue> get warnings => issues
      .where((i) => i.severity == PromptValidationSeverity.warning)
      .toList();
}

abstract class PromptValidator {
  PromptValidationResult validate({
    required PromptValidationContext context,
  });
}

class PromptValidationContext {
  const PromptValidationContext({
    required this.template,
    required this.variables,
    required this.systemText,
    required this.userText,
  });

  final dynamic template;
  final Map<String, dynamic> variables;
  final String systemText;
  final String userText;
}
