/// OR-1160 — Daily energy prompt builder.
library;

import '../core/prompt_domain.dart';
import 'base_prompt_builder.dart';
import 'prompt_inputs.dart';

class DailyEnergyPromptBuilder extends BasePromptBuilder<DailyEnergyPromptInput> {
  DailyEnergyPromptBuilder({
    required super.registry,
    required super.engine,
    required super.validator,
    super.templateVersion,
  });

  @override
  PromptDomain get domain => PromptDomain.dailyEnergy;

  @override
  String get builderId => 'daily_energy_prompt_builder';

  @override
  String get templateId => 'daily_energy.brief';

  @override
  Map<String, dynamic> mapInputToVariables(DailyEnergyPromptInput input) =>
      input.toVariables();
}
