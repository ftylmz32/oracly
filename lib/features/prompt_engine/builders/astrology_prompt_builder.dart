/// OR-1160 — Astrology prompt builder.
library;

import '../core/prompt_domain.dart';
import 'base_prompt_builder.dart';
import 'prompt_inputs.dart';

class AstrologyPromptBuilder extends BasePromptBuilder<AstrologyPromptInput> {
  AstrologyPromptBuilder({
    required super.registry,
    required super.engine,
    required super.validator,
    super.templateVersion,
  });

  @override
  PromptDomain get domain => PromptDomain.astrology;

  @override
  String get builderId => 'astrology_prompt_builder';

  @override
  String get templateId => 'astrology.reading';

  @override
  Map<String, dynamic> mapInputToVariables(AstrologyPromptInput input) =>
      input.toVariables();
}
