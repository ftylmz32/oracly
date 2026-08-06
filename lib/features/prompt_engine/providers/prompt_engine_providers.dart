/// OR-1160 — Prompt engine Riverpod providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../builders/astrology_prompt_builder.dart';
import '../builders/compatibility_prompt_builder.dart';
import '../builders/daily_energy_prompt_builder.dart';
import '../builders/dream_prompt_builder.dart';
import '../builders/numerology_prompt_builder.dart';
import '../builders/tarot_prompt_builder.dart';
import '../core/prompt_engine.dart';
import '../services/prompt_assembly_service.dart';
import '../services/token_estimation_service.dart';
import '../templates/catalogues/prompt_template_catalogue.dart';
import '../templates/template_engine.dart';
import '../templates/template_registry.dart';
import '../validators/prompt_validator.dart';

final templateRegistryProvider = Provider<TemplateRegistry>((ref) {
  return TemplateRegistry(templates: PromptTemplateCatalogue.bootstrap());
});

final templateEngineProvider = Provider<TemplateEngine>((ref) {
  return const TemplateEngine();
});

final promptValidatorProvider = Provider<PromptValidatorPipeline>((ref) {
  return PromptValidatorPipeline();
});

final tokenEstimationServiceProvider = Provider<TokenEstimationService>((ref) {
  return TokenEstimationService();
});

final promptEngineProvider = Provider<PromptEngine>((ref) {
  return PromptEngine(
    registry: ref.watch(templateRegistryProvider),
    validator: ref.watch(promptValidatorProvider),
    tokenEstimator: ref.watch(tokenEstimationServiceProvider),
  );
});

final promptAssemblyServiceProvider = Provider<PromptAssemblyService>((ref) {
  return ref.watch(promptEngineProvider).assembly;
});

final tarotPromptBuilderProvider = Provider<TarotPromptBuilder>((ref) {
  return TarotPromptBuilder(
    registry: ref.watch(templateRegistryProvider),
    engine: ref.watch(templateEngineProvider),
    validator: ref.watch(promptValidatorProvider),
  );
});

final dreamPromptBuilderProvider = Provider<DreamPromptBuilder>((ref) {
  return DreamPromptBuilder(
    registry: ref.watch(templateRegistryProvider),
    engine: ref.watch(templateEngineProvider),
    validator: ref.watch(promptValidatorProvider),
  );
});

final astrologyPromptBuilderProvider = Provider<AstrologyPromptBuilder>((ref) {
  return AstrologyPromptBuilder(
    registry: ref.watch(templateRegistryProvider),
    engine: ref.watch(templateEngineProvider),
    validator: ref.watch(promptValidatorProvider),
  );
});

final dailyEnergyPromptBuilderProvider =
    Provider<DailyEnergyPromptBuilder>((ref) {
  return DailyEnergyPromptBuilder(
    registry: ref.watch(templateRegistryProvider),
    engine: ref.watch(templateEngineProvider),
    validator: ref.watch(promptValidatorProvider),
  );
});

final compatibilityPromptBuilderProvider =
    Provider<CompatibilityPromptBuilder>((ref) {
  return CompatibilityPromptBuilder(
    registry: ref.watch(templateRegistryProvider),
    engine: ref.watch(templateEngineProvider),
    validator: ref.watch(promptValidatorProvider),
  );
});

final numerologyPromptBuilderProvider = Provider<NumerologyPromptBuilder>((ref) {
  return NumerologyPromptBuilder(
    registry: ref.watch(templateRegistryProvider),
    engine: ref.watch(templateEngineProvider),
    validator: ref.watch(promptValidatorProvider),
  );
});
