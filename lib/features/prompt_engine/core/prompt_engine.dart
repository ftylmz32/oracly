/// OR-1160 — Central prompt engine facade.
library;

import '../builders/astrology_prompt_builder.dart';
import '../builders/compatibility_prompt_builder.dart';
import '../builders/daily_energy_prompt_builder.dart';
import '../builders/dream_prompt_builder.dart';
import '../builders/numerology_prompt_builder.dart';
import '../builders/tarot_prompt_builder.dart';
import '../models/prompt_context.dart';
import '../services/prompt_assembly_service.dart';
import '../services/token_estimation_service.dart';
import '../templates/catalogues/prompt_template_catalogue.dart';
import '../templates/template_engine.dart';
import '../templates/template_registry.dart';
import '../validators/prompt_validator.dart';

class PromptEngine {
  factory PromptEngine({
    TemplateRegistry? registry,
    PromptValidatorPipeline? validator,
    TokenEstimationService? tokenEstimator,
  }) {
    final resolvedRegistry =
        registry ?? TemplateRegistry(templates: PromptTemplateCatalogue.bootstrap());
    const resolvedEngine = TemplateEngine();
    final resolvedValidator = validator ?? PromptValidatorPipeline();
    final resolvedEstimator = tokenEstimator ?? TokenEstimationService();

    return PromptEngine._(
      registry: resolvedRegistry,
      engine: resolvedEngine,
      validator: resolvedValidator,
      tokenEstimator: resolvedEstimator,
      assembly: PromptAssemblyService(
        registry: resolvedRegistry,
        tarotBuilder: TarotPromptBuilder(
          registry: resolvedRegistry,
          engine: resolvedEngine,
          validator: resolvedValidator,
        ),
        dreamBuilder: DreamPromptBuilder(
          registry: resolvedRegistry,
          engine: resolvedEngine,
          validator: resolvedValidator,
        ),
        astrologyBuilder: AstrologyPromptBuilder(
          registry: resolvedRegistry,
          engine: resolvedEngine,
          validator: resolvedValidator,
        ),
        dailyEnergyBuilder: DailyEnergyPromptBuilder(
          registry: resolvedRegistry,
          engine: resolvedEngine,
          validator: resolvedValidator,
        ),
        compatibilityBuilder: CompatibilityPromptBuilder(
          registry: resolvedRegistry,
          engine: resolvedEngine,
          validator: resolvedValidator,
        ),
        numerologyBuilder: NumerologyPromptBuilder(
          registry: resolvedRegistry,
          engine: resolvedEngine,
          validator: resolvedValidator,
        ),
        tokenEstimator: resolvedEstimator,
      ),
    );
  }

  PromptEngine._({
    required this.registry,
    required this.engine,
    required this.validator,
    required this.tokenEstimator,
    required this.assembly,
  });

  final TemplateRegistry registry;
  final TemplateEngine engine;
  final PromptValidatorPipeline validator;
  final TokenEstimationService tokenEstimator;
  final PromptAssemblyService assembly;

  PromptContext defaultContext({
    String locale = 'tr',
    String personality = 'mystical',
    String? sessionId,
    String? userName,
  }) {
    return PromptContext(
      locale: locale,
      personality: personality,
      sessionId: sessionId,
      userName: userName,
    );
  }
}
