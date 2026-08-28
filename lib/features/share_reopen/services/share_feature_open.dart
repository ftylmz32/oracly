/// Opens the matching feature. Never reads private ids from a URL.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import '../../../shared/navigation/oracly_shell_bridge.dart';
import '../../discovery_share/models/shareable_discovery.dart';

abstract final class ShareFeatureOpen {
  ShareFeatureOpen._();

  static void openPublic(BuildContext context, DiscoveryShareKind kind) {
    _open(context, kind, owner: false);
  }

  static void openAuthorized(BuildContext context, DiscoveryShareKind kind) {
    _open(context, kind, owner: true);
  }

  static void openSignIn(BuildContext context) {
    if (OraclyShellBridge.requestTab(OraclyTab.profile)) {
      Navigator.of(context).maybePop();
      return;
    }
    if (OraclyNavigationScope.maybeOf(context) != null) {
      OraclyNavigation.switchToTab(context, OraclyTab.profile);
      Navigator.of(context).maybePop();
      return;
    }
    OraclyNavigationService.openProfile(context);
  }

  static void _open(
    BuildContext context,
    DiscoveryShareKind kind, {
    required bool owner,
  }) {
    switch (kind) {
      case DiscoveryShareKind.tarot:
        owner
            ? OraclyNavigationService.openReadingHistory(context)
            : OraclyNavigationService.openTarotHome(context);
      case DiscoveryShareKind.coffee:
        OraclyNavigationService.openCoffee(context);
      case DiscoveryShareKind.palm:
        OraclyNavigationService.openPalm(context);
      case DiscoveryShareKind.astrology:
        OraclyNavigationService.openAstrology(context);
      case DiscoveryShareKind.starMap:
        OraclyNavigationService.openStarMap(context);
      case DiscoveryShareKind.soulMate:
        OraclyNavigationService.openPremium(context);
      case DiscoveryShareKind.dailyInsight:
        OraclyNavigationService.openDailyMessage(context);
    }
  }
}
