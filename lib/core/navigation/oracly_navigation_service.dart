/// OR-1120 — Central navigation coordinator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/daily_energy/navigation/daily_energy_route.dart';
import '../../features/daily_ritual/services/daily_ritual_intent.dart';
import '../../features/premium/presentation/screens/premium_screen.dart';
import '../../features/tarot/navigation/tarot_navigator.dart';
import '../../features/tarot/shared/constants/tarot_routes.dart';
import '../../shared/navigation/oracly_navigation.dart';
import '../../app/providers/app_providers.dart';
import '../modules/oracly_feature_id.dart';
import '../modules/oracly_feature_navigation.dart';
import 'oracly_route_generator.dart';
import 'oracly_routes.dart';

/// Connects every major screen without redesigning UI.
abstract final class OraclyNavigationService {
  OraclyNavigationService._();

  static void logScreen(WidgetRef ref, String name) {
    ref.read(analyticsServiceProvider).logScreenView(name);
  }

  // ── Tab navigation ─────────────────────────────────────────────

  static void openHome(BuildContext context) {
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }

  static void openTarotHome(BuildContext context) {
    OraclyNavigation.switchToTab(context, OraclyTab.tarot);
  }

  static void openProfile(BuildContext context) {
    OraclyNavigation.switchToTab(context, OraclyTab.profile);
  }

  static void openChat(BuildContext context) {
    OraclyNavigation.switchToTab(context, OraclyTab.chat);
  }

  // ── Feature screens ────────────────────────────────────────────

  static void openDailyEnergy(BuildContext context, {String? summary}) {
    DailyEnergyDetailsRoute.open(context, summary: summary);
  }

  static void openDream(BuildContext context) {
    _pushNamed(context, OraclyRoutes.dream);
  }

  static void openAstrology(BuildContext context) {
    _pushNamed(context, OraclyRoutes.astrology);
  }

  static void openStarMap(BuildContext context) {
    _pushNamed(context, OraclyRoutes.starMap);
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

  static void openReadingHistory(BuildContext context) {
    _pushNamed(context, OraclyRoutes.readingHistory);
  }

  static void openPersonalInsights(BuildContext context) {
    _pushNamed(context, OraclyRoutes.personalInsights);
  }

  static void openMemory(BuildContext context) {
    OraclyFeatureNavigation.open(context, OraclyFeatureId.memory);
  }

  static void openAchievements(BuildContext context) {
    _pushNamed(context, OraclyRoutes.achievements);
  }

  // ── Premium & settings ─────────────────────────────────────────

  static void openPremium(BuildContext context) {
    Navigator.of(context).push(premiumScreenRoute());
  }

  static void openSettings(BuildContext context) {
    _pushNamed(context, OraclyRoutes.settings);
  }

  static void openAbout(BuildContext context) {
    _pushNamed(context, OraclyRoutes.about);
  }

  static void openPrivacy(BuildContext context) {
    _pushNamed(context, OraclyRoutes.privacy);
  }

  // ── Deep linking helper ────────────────────────────────────────

  static void _pushNamed(BuildContext context, String routeName) {
    final route = OraclyRouteGenerator.onGenerateRoute(
      RouteSettings(name: routeName),
    );
    if (route != null) {
      Navigator.of(context).push(route);
    }
  }
}
