/// OR-1160 — Compatibility prompt builder.
library;

import '../core/prompt_domain.dart';
import 'base_prompt_builder.dart';
import 'prompt_inputs.dart';

class CompatibilityPromptBuilder
    extends BasePromptBuilder<CompatibilityPromptInput> {
  CompatibilityPromptBuilder({
    required super.registry,
    required super.engine,
    required super.validator,
    super.templateVersion,
  });

  @override
  PromptDomain get domain => PromptDomain.compatibility;

  @override
  String get builderId => 'compatibility_prompt_builder';

  @override
  String get templateId => 'compatibility.report';

  @override
  Map<String, dynamic> mapInputToVariables(CompatibilityPromptInput input) =>
      input.toVariables();
}
