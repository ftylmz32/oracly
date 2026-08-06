/// RC-011 — Default feature flag keys for experience coordination.
library;

abstract final class ExperienceFeatureFlags {
  ExperienceFeatureFlags._();

  static const personalInsights = 'personal_insights';
  static const dailyRitual = 'daily_ritual';
  static const premiumOffers = 'premium_offers';
  static const aiConversation = 'ai_conversation';
  static const journalHighlights = 'journal_highlights';

  static Map<String, bool> defaults({bool aiAvailable = true}) => {
        personalInsights: true,
        dailyRitual: true,
        premiumOffers: true,
        aiConversation: aiAvailable,
        journalHighlights: true,
      };
}
