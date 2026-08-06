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
  static const dailyEnergy = '/daily-energy';
  static const dream = '/dream';
  static const astrology = '/astrology';
  static const starMap = '/star-map';
  static const readingHistory = '/reading-history';
  static const personalInsights = '/personal-insights';

  /// Reserved route names — registered in [OraclyFeatureRegistry], not yet routed.
  static const numerology = '/numerology';
  static const moonCalendar = '/moon-calendar';
  static const manifestation = '/manifestation';

  static const achievements = '/achievements';
  static const about = '/about';
  static const privacy = '/privacy';
}
