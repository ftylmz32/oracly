/// RC-011 — Reflection style decisions.
library;

import '../../../../features/premium/models/personalization_models.dart';
import '../../../universe/oracly_ritual_time.dart';
import '../../domain/models/experience_feature_flags.dart';
import '../../domain/models/experience_orchestrator_input.dart';
import '../../domain/models/reflection_context.dart';

abstract final class ReflectionDecider {
  ReflectionDecider._();

  static ReflectionContext decide(ExperienceOrchestratorInput input) {
    final leadingTheme = input.reflectionSummary.recurringThemes.isEmpty
        ? null
        : input.reflectionSummary.recurringThemes.first.id;

    if (input.totalReadings == 0) {
      return const ReflectionContext(
        style: ReflectionStyle.invitation,
        surfacePersonalInsights: false,
        preferShortForm: true,
      );
    }

    if (input.ritualTime == OraclyRitualTime.night) {
      return ReflectionContext(
        style: ReflectionStyle.quiet,
        surfacePersonalInsights: _shouldSurfaceInsights(input),
        preferShortForm: true,
        leadingThemeId: leadingTheme,
      );
    }

    if (input.reflectionSummary.growthInsights.isNotEmpty) {
      return ReflectionContext(
        style: ReflectionStyle.deepening,
        surfacePersonalInsights: _shouldSurfaceInsights(input),
        preferShortForm: false,
        leadingThemeId: leadingTheme,
      );
    }

    if (input.hasRecurringPatterns) {
      return ReflectionContext(
        style: ReflectionStyle.observational,
        surfacePersonalInsights: _shouldSurfaceInsights(input),
        preferShortForm: input.settings.aiPersonality == AiPersonality.direct,
        leadingThemeId: leadingTheme,
      );
    }

    return ReflectionContext(
      style: ReflectionStyle.gentle,
      surfacePersonalInsights: false,
      preferShortForm: true,
      leadingThemeId: leadingTheme,
    );
  }

  static bool _shouldSurfaceInsights(ExperienceOrchestratorInput input) {
    if (!(input.featureFlags[ExperienceFeatureFlags.personalInsights] ??
        true)) {
      return false;
    }
    return input.hasRecurringPatterns && input.totalReadings >= 3;
  }
}