/// OR-438 — Module-aware navigation bridge (uses existing nav service).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../features/premium/services/premium_access.dart';
import '../../features/premium/services/soul_mate_navigation.dart';
import '../../screens/memory/memory_screen.dart';
import '../copy/first_session_copy.dart';
import '../navigation/oracly_navigation_service.dart';
import '../navigation/oracly_page_transitions.dart';
import '../../shared/ui/oracly_snackbar.dart';
import 'oracly_feature_id.dart';
import 'oracly_feature_module.dart';
import 'oracly_feature_registry.dart';

/// Opens a registered module without adding new navigation patterns.
abstract final class OraclyFeatureNavigation {
  OraclyFeatureNavigation._();

  static OraclyFeatureModule? module(OraclyFeatureId id) =>
      OraclyFeatureRegistry.byId(id);

  static bool canOpen(OraclyFeatureId id) {
    final m = module(id);
    if (m == null) return false;
    if (id == OraclyFeatureId.memory) return true;
    return m.isNavigable;
  }

  static void open(BuildContext context, OraclyFeatureId id) {
    if (id == OraclyFeatureId.soulMate &&
        _deferSoulMateForFirstSession(context)) {
      return;
    }
    final gated = module(id);
    if (gated != null &&
        gated.requiresPremium &&
        !PremiumAccess.ensure(context)) {
      PremiumAccess.prompt(context);
      return;
    }
    switch (id) {
      case OraclyFeatureId.home:
        OraclyNavigationService.openHome(context);
      case OraclyFeatureId.tarot:
        OraclyNavigationService.startTarotFlow(context);
      case OraclyFeatureId.coffee:
        OraclyNavigationService.openCoffee(context);
      case OraclyFeatureId.palm:
        OraclyNavigationService.openPalm(context);
      case OraclyFeatureId.aiChat:
        OraclyNavigationService.openChat(context);
      case OraclyFeatureId.profile:
        OraclyNavigationService.openProfile(context);
      case OraclyFeatureId.dream:
        OraclyNavigationService.openDream(context);
      case OraclyFeatureId.astrology:
        OraclyNavigationService.openAstrology(context);
      case OraclyFeatureId.starMap:
        OraclyNavigationService.openStarMap(context);
      case OraclyFeatureId.readingHistory:
        OraclyNavigationService.openReadingHistory(context);
      case OraclyFeatureId.discoveryJournal:
        OraclyNavigationService.openDiscoveryJournal(context);
      case OraclyFeatureId.personalInsights:
        OraclyNavigationService.openPersonalInsights(context);
      case OraclyFeatureId.dailyMessage:
        OraclyNavigationService.openDailyMessage(context);
      case OraclyFeatureId.memory:
        _openMemory(context);
      case OraclyFeatureId.achievements:
        _openReserved(context, id);
      case OraclyFeatureId.premium:
        OraclyNavigationService.openPremium(context);
      case OraclyFeatureId.settings:
        OraclyNavigationService.openSettings(context);
      case OraclyFeatureId.soulMate:
        SoulMateNavigation.open(context);
      case OraclyFeatureId.dailyEnergy:
        OraclyNavigationService.openDailyEnergy(context);
      case OraclyFeatureId.numerology:
      case OraclyFeatureId.moonCalendar:
      case OraclyFeatureId.manifestation:
        _openReserved(context, id);
    }
  }

  /// First session: free card before Premium Soul Mate paywall.
  static bool _deferSoulMateForFirstSession(BuildContext context) {
    if (PremiumAccess.isActive(context)) return false;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final first = container.read(isFirstSessionProvider).valueOrNull ?? false;
      if (!first) return false;
      OraclySnackBar.show(
        context,
        message: FirstSessionCopy.soulMateLater,
      );
      OraclyNavigationService.startDailyCardDraw(context);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _openMemory(BuildContext context) {
    Navigator.of(context).push(
      OraclyPageTransitions.enter<void>(page: const MemoryScreen()),
    );
  }

  static void _openReserved(BuildContext context, OraclyFeatureId id) {
    final m = module(id);
    if (m?.routeName == null || m!.isReserved) return;
    Navigator.of(context).pushNamed(m.routeName!);
  }

  static String? routeFor(OraclyFeatureId id) => module(id)?.routeName;
}
