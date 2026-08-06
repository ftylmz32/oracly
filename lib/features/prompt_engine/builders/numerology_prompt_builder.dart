/// OR-1160 — Numerology prompt builder.
library;

import '../core/prompt_domain.dart';
import 'base_prompt_builder.dart';
import 'prompt_inputs.dart';

class NumerologyPromptBuilder extends BasePromptBuilder<NumerologyPromptInput> {
  NumerologyPromptBuilder({
    required super.registry,
    required super.engine,
    required super.validator,
    super.templateVersion,
  });

  @override
  PromptDomain get domain => PromptDomain.numerology;

  @override
  String get builderId => 'numerology_prompt_builder';

  @override
  String get templateId => 'numerology.reading';

  @override
  Map<String, dynamic> mapInputToVariables(NumerologyPromptInput input) =>
      input.toVariables();
}
