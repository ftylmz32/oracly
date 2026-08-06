/// OR-438 — Module-aware navigation bridge (uses existing nav service).
library;

import 'package:flutter/material.dart';

import '../../screens/memory/memory_screen.dart';
import '../../shared/navigation/oracly_navigation.dart';
import '../navigation/oracly_navigation_service.dart';
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
    switch (id) {
      case OraclyFeatureId.home:
        OraclyNavigation.switchToTab(context, OraclyTab.home);
      case OraclyFeatureId.tarot:
        OraclyNavigation.switchToTab(context, OraclyTab.tarot);
      case OraclyFeatureId.aiChat:
        OraclyNavigation.switchToTab(context, OraclyTab.chat);
      case OraclyFeatureId.profile:
        OraclyNavigation.switchToTab(context, OraclyTab.profile);
      case OraclyFeatureId.dream:
        OraclyNavigationService.openDream(context);
      case OraclyFeatureId.astrology:
        OraclyNavigationService.openAstrology(context);
      case OraclyFeatureId.starMap:
        OraclyNavigationService.openStarMap(context);
      case OraclyFeatureId.readingHistory:
        OraclyNavigationService.openReadingHistory(context);
      case OraclyFeatureId.personalInsights:
        OraclyNavigationService.openPersonalInsights(context);
      case OraclyFeatureId.memory:
        _openMemory(context);
      case OraclyFeatureId.achievements:
        OraclyNavigationService.openAchievements(context);
      case OraclyFeatureId.premium:
        OraclyNavigationService.openPremium(context);
      case OraclyFeatureId.settings:
        OraclyNavigationService.openSettings(context);
      case OraclyFeatureId.dailyEnergy:
        OraclyNavigationService.openDailyEnergy(context);
      case OraclyFeatureId.numerology:
      case OraclyFeatureId.moonCalendar:
      case OraclyFeatureId.manifestation:
        _openReserved(context, id);
    }
  }

  static void _openMemory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MemoryScreen()),
    );
  }

  static void _openReserved(BuildContext context, OraclyFeatureId id) {
    final m = module(id);
    if (m?.routeName == null || m!.isReserved) return;
    Navigator.of(context).pushNamed(m.routeName!);
  }

  static String? routeFor(OraclyFeatureId id) => module(id)?.routeName;
}
