/// OR-1160 — Dream prompt builder.
library;

import '../core/prompt_domain.dart';
import 'base_prompt_builder.dart';
import 'prompt_inputs.dart';

class DreamPromptBuilder extends BasePromptBuilder<DreamPromptInput> {
  DreamPromptBuilder({
    required super.registry,
    required super.engine,
    required super.validator,
    super.templateVersion,
  });

  @override
  PromptDomain get domain => PromptDomain.dream;

  @override
  String get builderId => 'dream_prompt_builder';

  @override
  String get templateId => 'dream.analysis';

  @override
  Map<String, dynamic> mapInputToVariables(DreamPromptInput input) =>
      input.toVariables();
}
