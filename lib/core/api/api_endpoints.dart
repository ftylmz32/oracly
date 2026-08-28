/// OR-1130 — API endpoint path registry — no hardcoded full URLs.
library;

import '../config/app_config.dart';

abstract final class ApiEndpoints {
  ApiEndpoints._();

  static String get _base => AppConfig.instance.apiBaseUrl;
  static String get _version => AppConfig.instance.apiVersion;
  static String get _prefix => '$_base/$_version';

  // Auth
  static String get authAnonymous => '$_prefix/auth/anonymous';
  static String get authGoogle => '$_prefix/auth/google';
  static String get authApple => '$_prefix/auth/apple';
  static String get authEmail => '$_prefix/auth/email';
  static String get authRefresh => '$_prefix/auth/refresh';
  static String get authLogout => '$_prefix/auth/logout';

  // User
  static String get userProfile => '$_prefix/users/me';
  static String get userAchievements => '$_prefix/users/me/achievements';

  // Tarot
  static String get tarotDecks => '$_prefix/tarot/decks';
  static String tarotDeck(String id) => '$_prefix/tarot/decks/$id';
  static String get tarotSpreads => '$_prefix/tarot/spreads';

  // Readings
  static String get readings => '$_prefix/readings';
  static String reading(String id) => '$_prefix/readings/$id';

  // Dreams
  static String get dreams => '$_prefix/dreams';
  static String dream(String id) => '$_prefix/dreams/$id';

  // Astrology
  static String get astrologyCharts => '$_prefix/astrology/charts';
  static String get astrologyHoroscope => '$_prefix/astrology/horoscope';

  // Daily energy
  static String get dailyEnergy => '$_prefix/daily-energy';
  static String dailyEnergyByDate(String date) => '$_prefix/daily-energy/$date';

  // AI
  static String get aiConversations => '$_prefix/ai/conversations';
  static String aiConversation(String id) => '$_prefix/ai/conversations/$id';
  static String get aiComplete => '$_prefix/ai/complete';
  static String get aiStream => '$_prefix/ai/stream';

  // Premium
  static String get premiumPlans => '$_prefix/premium/plans';
  static String get premiumSubscribe => '$_prefix/premium/subscribe';
  static String get premiumStatus => '$_prefix/premium/status';
  static String get billingVerify => '$_prefix/billing/verify';

  // Settings
  static String get settings => '$_prefix/settings/me';

  // Sync
  static String get syncPush => '$_prefix/sync/push';
  static String get syncPull => '$_prefix/sync/pull';
}
