/// OR-1120 — Central navigation coordinator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../features/companion/providers/companion_providers.dart';
import '../../features/companion/services/or_chat_handoff.dart';
import '../../features/daily_ritual/services/daily_ritual_intent.dart';
import '../../features/tarot/navigation/tarot_navigator.dart';
import '../../features/tarot/shared/constants/tarot_routes.dart';
import '../../features/tarot/shared/tarot_scope.dart';
import '../../shared/navigation/oracly_navigation.dart';
import '../../shared/navigation/oracly_shell_bridge.dart';
import '../../app/providers/app_providers.dart';
import '../modules/oracly_feature_id.dart';
import '../telemetry/crash_feature_context.dart';
import '../modules/oracly_feature_navigation.dart';
import 'oracly_route_generator.dart';
import 'oracly_routes.dart';

/// Connects every major screen without redesigning UI.
abstract final class OraclyNavigationService {
  OraclyNavigationService._();

  static void logScreen(WidgetRef ref, String name) {
    CrashFeatureContext.applyScreen(name);
    ref.read(analyticsServiceProvider).logScreenView(name);
  }

  // ── Tab navigation ─────────────────────────────────────────────

  static void openHome(BuildContext context) {
    // Never push another [OraclyAppShell] — only the live shell may host Home.
    _openExistingTab(context, OraclyTab.home);
  }

  static void openTarotHome(BuildContext context) {
    if (TarotScope.maybeOf(context) != null) return;
    _pushNamed(context, OraclyRoutes.tarot);
  }

  /// Keşfet shell tab — Explore hub (Coffee is a pushed chamber).
  static void openExploreTab(BuildContext context) {
    _openExistingTab(context, OraclyTab.astrology);
  }

  /// Coffee chamber — always push; never hijack Keşfet.
  static void openCoffeeTab(BuildContext context) {
    _pushNamed(context, OraclyRoutes.coffee);
  }

  static void openCoffee(BuildContext context) {
    openCoffeeTab(context);
  }

  static void openProfile(BuildContext context) {
    // Profile is a shell tab — never stack a second shell for it.
    _openExistingTab(context, OraclyTab.profile);
  }

  /// Canonical OR — shell tab (enum coffee) when available; else push /chat.
  static void openChat(
    BuildContext context, {
    OracleReadingContext? readingContext,
  }) {
    if (readingContext != null) {
      OrChatHandoffBuffer.offer(readingContext);
    }
    if (_isTopNamedRoute(context, OraclyRoutes.chat)) {
      final handoff = OrChatHandoffBuffer.take();
      if (handoff != null) {
        ProviderScope.containerOf(context, listen: false)
            .read(companionControllerProvider)
            .applyReadingHandoff(handoff);
      }
      return;
    }
    if (_openExistingTab(context, OraclyTab.coffee)) {
      final handoff = OrChatHandoffBuffer.take();
      if (handoff != null) {
        ProviderScope.containerOf(context, listen: false)
            .read(companionControllerProvider)
            .applyReadingHandoff(handoff);
      }
      return;
    }
    _pushNamed(context, OraclyRoutes.chat);
  }

  // ── Feature screens ────────────────────────────────────────────

  /// Live path goes to Home Daily Ritual — not fake energy details.
  static void openDailyEnergy(BuildContext context) {
    openHome(context);
  }

  static void openDream(BuildContext context) {
    _pushNamed(context, OraclyRoutes.dream);
  }

  /// Astrology is a pushed chamber — shell tab index 2 is Keşfet (Explore).
  static void openAstrology(BuildContext context) {
    _pushNamed(context, OraclyRoutes.astrology);
  }

  /// Yıldızname is a pushed chamber — shell tab index 3 is Günlük.
  static void openStarMap(BuildContext context) {
    _pushNamed(context, OraclyRoutes.starMap);
  }

  /// Prefer the live shell tab; never stack a second [OraclyAppShell].
  static bool _openExistingTab(BuildContext context, OraclyTab tab) {
    if (OraclyNavigationScope.maybeOf(context) != null) {
      OraclyNavigation.switchToTab(context, tab);
      return true;
    }
    return OraclyShellBridge.requestTab(tab);
  }

  // ── Tarot ritual flow ──────────────────────────────────────────

  static Future<void> openTarotModuleRoute(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return TarotNavigator.pushNamed(context, route, arguments: arguments);
  }

  static void startTarotFlow(BuildContext context, {String? spreadType}) {
    if (TarotScope.maybeOf(context) == null) {
      openTarotHome(context);
      return;
    }
    openTarotModuleRoute(context, TarotRoutes.deckSelection);
  }

  /// Gentle daily ritual — single card, no gamification.
  static void startDailyCardDraw(BuildContext context) {
    DailyRitualIntent.requestDailyCardDraw();
    openTarotHome(context);
  }

  static void openDeckSelection(BuildContext context) {
    openTarotModuleRoute(context, TarotRoutes.deckSelection);
  }

  static void openShuffle(BuildContext context) {
    openTarotModuleRoute(context, TarotRoutes.shuffle);
  }

  static void openCardSelection(BuildContext context) {
    openTarotModuleRoute(context, TarotRoutes.cardSelection);
  }

  static void openCardReveal(BuildContext context, int cardIndex) {
    openTarotModuleRoute(
      context,
      TarotRoutes.cardReveal,
      arguments: cardIndex,
    );
  }

  static void openAiReading(BuildContext context, int cardIndex) {
    openTarotModuleRoute(
      context,
      TarotRoutes.reading,
      arguments: cardIndex,
    );
  }

  static void openCardDetail(BuildContext context, int cardId) {
    openTarotModuleRoute(
      context,
      TarotRoutes.cardDetail,
      arguments: cardId,
    );
  }

  static void openDestem(BuildContext context) {
    openTarotModuleRoute(context, TarotRoutes.destem);
  }

  static void openReadingHistory(BuildContext context) {
    _pushNamed(context, OraclyRoutes.readingHistory);
  }

  static void openDiscoveryJournal(BuildContext context) {
    if (_openExistingTab(context, OraclyTab.starMap)) return;
    _pushNamed(context, OraclyRoutes.discoveryJournal);
  }

  static void openMyStory(BuildContext context) {
    _pushNamed(context, OraclyRoutes.myStory);
  }

  static void openFavoriteMoments(BuildContext context) {
    _pushNamed(context, OraclyRoutes.favoriteMoments);
  }

  static void openPersonalInsights(BuildContext context) {
    _pushNamed(context, OraclyRoutes.personalInsights);
  }

  static void openDailyMessage(BuildContext context) {
    _pushNamed(context, OraclyRoutes.dailyMessage);
  }

  static void openPalm(BuildContext context) {
    _pushNamed(context, OraclyRoutes.palm);
  }

  static void openMemory(BuildContext context) {
    OraclyFeatureNavigation.open(context, OraclyFeatureId.memory);
  }

  static void openAchievements(BuildContext context) {
    _pushNamed(context, OraclyRoutes.achievements);
  }

  // ── Premium & settings ─────────────────────────────────────────

  static void openPremium(BuildContext context) {
    _pushNamed(context, OraclyRoutes.premium);
  }

  static void openGems(BuildContext context) {
    _pushNamed(context, OraclyRoutes.gems);
  }

  static void openDailyRewards(BuildContext context) {
    _pushNamed(context, OraclyRoutes.dailyRewards);
  }

  static void openSettings(BuildContext context) {
    _pushNamed(context, OraclyRoutes.settings);
  }

  static void openAbout(BuildContext context) {
    _pushNamed(context, OraclyRoutes.about);
  }

  static void openHelp(BuildContext context) {
    _pushNamed(context, OraclyRoutes.help);
  }

  static void openPrivacy(BuildContext context) {
    _pushNamed(context, OraclyRoutes.privacy);
  }

  // ── Deep linking helper ────────────────────────────────────────

  /// Peek at the navigator top without popping — blocks duplicate pushes.
  static bool _isTopNamedRoute(BuildContext context, String routeName) {
    Route<dynamic>? top;
    Navigator.of(context).popUntil((route) {
      top = route;
      return true;
    });
    return top?.settings.name == routeName;
  }

  static void _pushNamed(BuildContext context, String routeName) {
    if (_isTopNamedRoute(context, routeName)) return;
    final route = OraclyRouteGenerator.onGenerateRoute(
      RouteSettings(name: routeName),
    );
    if (route != null) {
      Navigator.of(context).push(route);
    }
  }
}
