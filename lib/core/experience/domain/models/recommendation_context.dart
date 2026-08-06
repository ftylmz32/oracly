/// RC-011 — Experience highlight and premium relevance.
library;

enum ExperienceHighlight {
  none,
  dailyRitual,
  personalInsight,
  premium,
  reading,
  journal,
}

class PremiumRelevance {
  const PremiumRelevance({
    required this.isRelevant,
    this.reasonKey,
  });

  final bool isRelevant;
  final String? reasonKey;
}

class RecommendationContext {
  const RecommendationContext({
    required this.primaryHighlight,
    required this.secondaryHighlights,
    required this.premium,
    required this.aiAvailable,
    required this.featureFlags,
  });

  final ExperienceHighlight primaryHighlight;
  final List<ExperienceHighlight> secondaryHighlights;
  final PremiumRelevance premium;
  final bool aiAvailable;
  final Map<String, bool> featureFlags;
}
