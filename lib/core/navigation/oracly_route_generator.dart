/// OR-1120 — Deep-link ready route generator.
library;

import 'package:flutter/material.dart';

import '../../features/coffee/presentation/reference/coffee_reference_screen.dart';
import '../../features/palm/presentation/palm_reference_screen.dart';
import '../../features/companion/presentation/reference/companion_reference_screen.dart';
import '../../features/astrology/presentation/reference/astrology_reference_screen.dart';
import '../../features/dream/presentation/reference/dream_reference_screen.dart';
import '../../features/daily_message/presentation/screens/daily_message_screen.dart';
import '../../features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import '../../features/favorite_moments/presentation/screens/favorite_moments_screen.dart';
import '../../features/my_story/presentation/screens/my_story_screen.dart';
import '../../features/insights/presentation/screens/personal_insights_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/daily_rewards/presentation/reference/daily_rewards_reference_screen.dart';
import '../../features/gems/presentation/reference/gems_reference_screen.dart';
import '../../features/premium/presentation/reference/premium_reference_screen.dart';
import '../../features/star_map/presentation/reference/star_map_reference_screen.dart';
import '../../features/tarot/navigation/tarot_module_navigator.dart';
import '../../features/tarot/presentation/screens/reading_history_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../screens/about/about_screen.dart';
import '../../screens/privacy/privacy_screen.dart';
import '../../screens/profile/achievements_screen.dart';
import '../../screens/settings/reference/settings_reference_screen.dart';
import '../../features/share_reopen/presentation/share_reopen_screen.dart';
import '../../features/share_reopen/services/share_link_parser.dart';
import '../../shared/navigation/oracly_navigation.dart';
import '../navigation/oracly_page_transitions.dart';
import 'immersive/chamber_transition_personality.dart';
import 'oracly_routes.dart';

abstract final class OraclyRouteGenerator {
  OraclyRouteGenerator._();

  /// Resolves named routes for deep linking and programmatic navigation.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final shareUri = ShareLinkParser.parse(settings.name);
    if (shareUri != null) {
      return OraclyPageTransitions.fade(
        page: ShareReopenScreen(uri: shareUri),
        settings: settings,
      );
    }
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
      case OraclyRoutes.tarot:
        return OraclyPageTransitions.chamber(
          personality: ChamberTransitionPersonality.tarot,
          page: const TarotModuleNavigator(),
          settings: settings,
        );
      case OraclyRoutes.settings:
        return OraclyPageTransitions.slideUp(
          page: const SettingsReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.premium:
        return premiumScreenRoute(settings: settings);
      case OraclyRoutes.gems:
        return OraclyPageTransitions.slideUp(
          page: const GemsReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.dailyRewards:
        return OraclyPageTransitions.slideUp(
          page: const DailyRewardsReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.dream:
        return OraclyPageTransitions.sharedAxis(
          page: const DreamReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.chat:
        return OraclyPageTransitions.chamber(
          personality: ChamberTransitionPersonality.orPresence,
          page: const CompanionReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.profile:
        return OraclyPageTransitions.fade(
          page: const OraclyAppShell(initialTab: OraclyTab.profile),
          settings: settings,
        );
      case OraclyRoutes.astrology:
        return OraclyPageTransitions.chamber(
          personality: ChamberTransitionPersonality.astrology,
          page: const AstrologyReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.starMap:
        return OraclyPageTransitions.chamber(
          personality: ChamberTransitionPersonality.yildizname,
          page: const StarMapReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.coffee:
        return OraclyPageTransitions.chamber(
          personality: ChamberTransitionPersonality.coffee,
          page: const CoffeeReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.palm:
        return OraclyPageTransitions.sharedAxis(
          page: const PalmReferenceScreen(),
          settings: settings,
        );
      case OraclyRoutes.readingHistory:
        return OraclyPageTransitions.fade(
          page: const ReadingHistoryScreen(),
          settings: settings,
        );
      case OraclyRoutes.discoveryJournal:
        return OraclyPageTransitions.fade(
          page: const DiscoveryJournalScreen(),
          settings: settings,
        );
      case OraclyRoutes.myStory:
        return OraclyPageTransitions.fade(
          page: const MyStoryScreen(),
          settings: settings,
        );
      case OraclyRoutes.favoriteMoments:
        return OraclyPageTransitions.fade(
          page: const FavoriteMomentsScreen(),
          settings: settings,
        );
      case OraclyRoutes.personalInsights:
        return OraclyPageTransitions.fade(
          page: const PersonalInsightsScreen(),
          settings: settings,
        );
      case OraclyRoutes.dailyMessage:
        return OraclyPageTransitions.fade(
          page: const DailyMessageScreen(),
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
      case OraclyRoutes.help:
        return OraclyPageTransitions.slideUp(
          page: const HelpScreen(),
          settings: settings,
        );
      case OraclyRoutes.privacy:
        return OraclyPageTransitions.slideUp(
          page: const PrivacyScreen(),
          settings: settings,
        );
      case OraclyRoutes.dailyEnergy:
        // Live path is Home daily ritual — never a broken details route.
        return OraclyPageTransitions.fade(
          page: const OraclyAppShell(),
          settings: settings,
        );
      default:
        // Unknown / reserved deep links recover to the live shell.
        return OraclyPageTransitions.fade(
          page: const OraclyAppShell(),
          settings: settings,
        );
    }
  }
}
