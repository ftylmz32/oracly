/// OR-438 — String key constants for future localization.
library;

/// Semantic string keys — migrate copy incrementally; new modules use these first.
abstract final class L10nKeys {
  L10nKeys._();

  // Navigation / shell
  static const home = 'nav.home';
  static const tarot = 'nav.tarot';
  static const chat = 'nav.chat';
  static const profile = 'nav.profile';

  // Features
  static const tarotReading = 'feature.tarot.title';
  static const aiChat = 'feature.ai_chat.title';
  static const dream = 'feature.dream.title';
  static const astrology = 'feature.astrology.title';
  static const numerology = 'feature.numerology.title';
  static const moonCalendar = 'feature.moon_calendar.title';
  static const manifestation = 'feature.manifestation.title';

  // Settings
  static const settingsTitle = 'settings.title';
  static const language = 'settings.language';

  // Common
  static const save = 'common.save';
  static const cancel = 'common.cancel';
  static const comingSoon = 'common.coming_soon';
}
