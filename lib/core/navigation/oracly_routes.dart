/// OR-1120 — Central route names for navigation and deep linking.
library;

abstract final class OraclyRoutes {
  OraclyRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const tarot = '/tarot';
  static const chat = '/chat';
  static const profile = '/profile';
  static const settings = '/settings';
  static const premium = '/premium';
  static const gems = '/gems';
  static const dailyRewards = '/daily-rewards';
  static const dailyEnergy = '/daily-energy';
  static const dream = '/dream';
  static const astrology = '/astrology';
  static const starMap = '/star-map';
  static const coffee = '/coffee';
  static const palm = '/palm';
  static const readingHistory = '/reading-history';
  static const discoveryJournal = '/discovery-journal';
  static const myStory = '/my-story';
  static const favoriteMoments = '/favorite-moments';
  static const personalInsights = '/personal-insights';
  static const dailyMessage = '/daily-message';

  /// Reserved route names — registered in [OraclyFeatureRegistry], not yet routed.
  static const numerology = '/numerology';
  static const moonCalendar = '/moon-calendar';
  static const manifestation = '/manifestation';

  static const achievements = '/achievements';
  static const about = '/about';
  static const help = '/help';
  static const privacy = '/privacy';
  static const share = '/share';
}
