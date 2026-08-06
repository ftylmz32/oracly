/// OR-1120 — Deep-link ready route generator.
library;

import 'package:flutter/material.dart';

import '../../features/astrology/presentation/screens/astrology_screen.dart';
import '../../features/dream/presentation/screens/dream_screen.dart';
import '../../features/insights/presentation/screens/personal_insights_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/premium/presentation/screens/premium_screen.dart';
import '../../features/star_map/presentation/screens/star_map_screen.dart';
import '../../features/tarot/presentation/screens/reading_history_screen.dart';
import '../../screens/about/about_screen.dart';
import '../../screens/privacy/privacy_screen.dart';
import '../../screens/profile/achievements_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../shared/navigation/oracly_navigation.dart';
import '../navigation/oracly_page_transitions.dart';
import 'oracly_routes.dart';

abstract final class OraclyRouteGenerator {
  OraclyRouteGenerator._();

  /// Resolves named routes for deep linking and programmatic navigation.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case OraclyRoutes.onboarding:
        return OraclyPageTransitions.fade(
          page: const OnboardingScreen(),
          settings: settings,
        );
      case OraclyRoutes.home:
        return OraclyPageTransitions.fade(
          page: const OraclyAppShell(),
          settings: settings,
        );
      case OraclyRoutes.settings:
        return OraclyPageTransitions.slideUp(
          page: const SettingsScreen(),
          settings: settings,
        );
      case OraclyRoutes.premium:
        return premiumScreenRoute(settings: settings);
      case OraclyRoutes.dream:
        return OraclyPageTransitions.sharedAxis(
          page: const DreamScreen(),
          settings: settings,
        );
      case OraclyRoutes.astrology:
        return OraclyPageTransitions.sharedAxis(
          page: const AstrologyScreen(),
          settings: settings,
        );
      case OraclyRoutes.starMap:
        return OraclyPageTransitions.sharedAxis(
          page: const StarMapScreen(),
          settings: settings,
        );
      case OraclyRoutes.readingHistory:
        return OraclyPageTransitions.fade(
          page: const ReadingHistoryScreen(),
          settings: settings,
        );
      case OraclyRoutes.personalInsights:
        return OraclyPageTransitions.fade(
          page: const PersonalInsightsScreen(),
          settings: settings,
        );
      case OraclyRoutes.achievements:
        return OraclyPageTransitions.slideUp(
          page: const AchievementsScreen(),
          settings: settings,
        );
      case OraclyRoutes.about:
        return OraclyPageTransitions.slideUp(
          page: const AboutScreen(),
          settings: settings,
        );
      case OraclyRoutes.privacy:
        return OraclyPageTransitions.slideUp(
          page: const PrivacyScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
