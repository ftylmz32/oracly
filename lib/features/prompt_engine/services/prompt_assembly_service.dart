/// OR-1160 — Orchestrates build, validate, estimate, and parse.
library;

import '../builders/prompt_inputs.dart';
import '../builders/tarot_prompt_builder.dart';
import '../builders/dream_prompt_builder.dart';
import '../builders/astrology_prompt_builder.dart';
import '../builders/daily_energy_prompt_builder.dart';
import '../builders/compatibility_prompt_builder.dart';
import '../builders/numerology_prompt_builder.dart';
import '../core/prompt_domain.dart';
import '../formatters/structured_response_parser.dart';
import '../models/prompt_context.dart';
import '../models/prompt_metadata.dart';
import '../models/prompt_request.dart';
import '../models/prompt_response.dart';
import '../services/token_estimation_service.dart';
import '../templates/template_registry.dart';

class PromptAssemblyService {
  PromptAssemblyService({
    required this.registry,
    required this.tarotBuilder,
    required this.dreamBuilder,
    required this.astrologyBuilder,
    required this.dailyEnergyBuilder,
    required this.compatibilityBuilder,
    required this.numerologyBuilder,
    required this.tokenEstimator,
    this.responseParser = const StructuredResponseParser(),
  });

  final TemplateRegistry registry;
  final TarotPromptBuilder tarotBuilder;
  final DreamPromptBuilder dreamBuilder;
  final AstrologyPromptBuilder astrologyBuilder;
  final DailyEnergyPromptBuilder dailyEnergyBuilder;
  final CompatibilityPromptBuilder compatibilityBuilder;
  final NumerologyPromptBuilder numerologyBuilder;
  final TokenEstimationService tokenEstimator;
  final StructuredResponseParser responseParser;

  PromptRequest buildTarot({
    required TarotPromptInput input,
    required PromptContext context,
  }) =>
      _withEstimate(
        tarotBuilder.build(input: input, context: context),
        'tarot.reading',
      );

  PromptRequest buildDream({
    required DreamPromptInput input,
    required PromptContext context,
  }) =>
      _withEstimate(
        dreamBuilder.build(input: input, context: context),
        'dream.analysis',
      );

  PromptRequest buildAstrology({
    required AstrologyPromptInput input,
    required PromptContext context,
  }) =>
      _withEstimate(
        astrologyBuilder.build(input: input, context: context),
        'astrology.reading',
      );

  PromptRequest buildDailyEnergy({
    required DailyEnergyPromptInput input,
    required PromptContext context,
  }) =>
      _withEstimate(
        dailyEnergyBuilder.build(input: input, context: context),
        'daily_energy.brief',
      );

  PromptRequest buildCompatibility({
    required CompatibilityPromptInput input,
    required PromptContext context,
  }) =>
      _withEstimate(
        compatibilityBuilder.build(input: input, context: context),
        'compatibility.report',
      );

  PromptRequest buildNumerology({
    required NumerologyPromptInput input,
    required PromptContext context,
  }) =>
      _withEstimate(
        numerologyBuilder.build(input: input, context: context),
        'numerology.reading',
      );

  PromptRequest buildForDomain({
    required PromptDomain domain,
    required Map<String, dynamic> input,
    required PromptContext context,
  }) {
    switch (domain) {
      case PromptDomain.tarot:
        return buildTarot(
          input: TarotPromptInput(
            spreadType: input['spreadType'] as String? ?? '',
            intention: input['intention'] as String? ?? '',
            cardsSummary: input['cardsSummary'] as String? ?? '',
            reversedSummary: input['reversedSummary'] as String?,
          ),
          context: context,
        );
      case PromptDomain.dream:
        return buildDream(
          input: DreamPromptInput(
            dreamText: input['dreamText'] as String? ?? '',
            emotions: (input['emotions'] as List?)?.cast<String>() ?? const [],
            symbols: (input['symbols'] as List?)?.cast<String>() ?? const [],
          ),
          context: context,
        );
      case PromptDomain.astrology:
        return buildAstrology(
          input: AstrologyPromptInput(
            zodiacSign: input['zodiacSign'] as String? ?? '',
            question: input['question'] as String? ?? '',
            birthDate: input['birthDate'] as String?,
            birthTime: input['birthTime'] as String?,
            birthPlace: input['birthPlace'] as String?,
          ),
          context: context,
        );
      case PromptDomain.dailyEnergy:
        return buildDailyEnergy(
          input: DailyEnergyPromptInput(
            date: input['date'] as String? ?? '',
            energyLevel: input['energyLevel'] as num? ?? 0,
            moodLabel: input['moodLabel'] as String? ?? '',
            zodiacSign: input['zodiacSign'] as String?,
            focusArea: input['focusArea'] as String?,
          ),
          context: context,
        );
      case PromptDomain.compatibility:
        return buildCompatibility(
          input: CompatibilityPromptInput(
            subjectA: input['subjectA'] as String? ?? '',
            subjectB: input['subjectB'] as String? ?? '',
            chartSummary: input['chartSummary'] as String?,
          ),
          context: context,
        );
      case PromptDomain.numerology:
        return buildNumerology(
          input: NumerologyPromptInput(
            birthDate: input['birthDate'] as String? ?? '',
            lifePathNumber: input['lifePathNumber'] as int? ?? 0,
            fullName: input['fullName'] as String?,
            nameNumber: input['nameNumber'] as int?,
          ),
          context: context,
        );
    }
  }

  PromptResponse parseResponse({
    required String rawText,
    required PromptMetadata metadata,
  }) {
    return PromptResponse(
      rawText: rawText,
      metadata: metadata,
      structured: responseParser.parse(rawText),
    );
  }

  PromptRequest _withEstimate(PromptRequest request, String templateId) {
    final template = registry.resolve(id: templateId);
    final estimate = tokenEstimator.estimateForTemplate(template, request);
    return request.copyWith(
      metadata: request.metadata.copyWith(
        estimatedInputTokens: estimate.inputTokens,
        estimatedOutputTokens: estimate.outputTokens,
        estimatedCostUsd: estimate.estimatedCostUsd,
      ),
    );
  }
}
