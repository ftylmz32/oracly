/// OR-1160 — Tarot prompt builder.
library;

import '../core/prompt_domain.dart';
import 'base_prompt_builder.dart';
import 'prompt_inputs.dart';

class TarotPromptBuilder extends BasePromptBuilder<TarotPromptInput> {
  TarotPromptBuilder({
    required super.registry,
    required super.engine,
    required super.validator,
    super.templateVersion,
  });

  @override
  PromptDomain get domain => PromptDomain.tarot;

  @override
  String get builderId => 'tarot_prompt_builder';

  @override
  String get templateId => 'tarot.reading';

  @override
  Map<String, dynamic> mapInputToVariables(TarotPromptInput input) =>
      input.toVariables();
}
