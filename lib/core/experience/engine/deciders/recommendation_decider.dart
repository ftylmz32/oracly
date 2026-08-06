/// RC-011 — Highlight and premium relevance decisions.
library;

import '../../domain/models/experience_feature_flags.dart';
import '../../domain/models/experience_orchestrator_input.dart';
import '../../domain/models/recommendation_context.dart';
import 'journey_decider.dart';
import 'reflection_decider.dart';

abstract final class RecommendationDecider {
  RecommendationDecider._();

  static RecommendationContext decide(ExperienceOrchestratorInput input) {
    final highlights = _rankHighlights(input);
    final primary =
        highlights.isEmpty ? ExperienceHighlight.none : highlights.first;
    final secondary = highlights.length <= 1
        ? const <ExperienceHighlight>[]
        : highlights.sublist(1);

    return RecommendationContext(
      primaryHighlight: primary,
      secondaryHighlights: secondary,
      premium: _premiumRelevance(input),
      aiAvailable: input.aiAvailable &&
          (input.featureFlags[ExperienceFeatureFlags.aiConversation] ?? true),
      featureFlags: Map.unmodifiable(input.featureFlags),
    );
  }

  static List<ExperienceHighlight> _rankHighlights(
    ExperienceOrchestratorInput input,
  ) {
    final ranked = <ExperienceHighlight>[];

    if (JourneyDecider.decide(input).highlightTodaysRitual) {
      ranked.add(ExperienceHighlight.dailyRitual);
    }

    if (ReflectionDecider.decide(input).surfacePersonalInsights) {
      ranked.add(ExperienceHighlight.personalInsight);
    }

    if (input.totalReadings == 0) {
      ranked.add(ExperienceHighlight.reading);
    } else if (input.reflectionCount == 0 &&
        (input.featureFlags[ExperienceFeatureFlags.journalHighlights] ??
            true)) {
      ranked.add(ExperienceHighlight.journal);
    }

    final premium = _premiumRelevance(input);
    if (premium.isRelevant) {
      ranked.add(ExperienceHighlight.premium);
    }

    return ranked;
  }

  static PremiumRelevance _premiumRelevance(ExperienceOrchestratorInput input) {
    if (input.premiumActive) {
      return const PremiumRelevance(isRelevant: false);
    }
    if (!(input.featureFlags[ExperienceFeatureFlags.premiumOffers] ?? true)) {
      return const PremiumRelevance(isRelevant: false);
    }

    if (input.totalReadings >= 5 && input.hasRecurringPatterns) {
      return const PremiumRelevance(
        isRelevant: true,
        reasonKey: 'premium_journey_depth',
      );
    }

    if (input.totalReadings >= 3) {
      return const PremiumRelevance(
        isRelevant: true,
        reasonKey: 'premium_continuity',
      );
    }

    return const PremiumRelevance(isRelevant: false);
  }
}
