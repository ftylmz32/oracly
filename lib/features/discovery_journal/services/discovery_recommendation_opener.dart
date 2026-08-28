/// Opens the one recommended chamber — never Home.
library;

import 'package:flutter/material.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../personal_discovery/models/discovery_recommended_feature.dart';

abstract final class DiscoveryRecommendationOpener {
  DiscoveryRecommendationOpener._();

  static void open(
    BuildContext context,
    DiscoveryRecommendedFeature feature, {
    String? theme,
  }) {
    switch (feature) {
      case DiscoveryRecommendedFeature.dream:
        OraclyNavigationService.openDream(context);
      case DiscoveryRecommendedFeature.companion:
        final label = (theme ?? '').trim();
        if (label.isNotEmpty) {
          openOracleConversation(
            context,
            readingContext: OracleReadingContextSources.discoveryJournal(
              id: 'journal_rec_${label.hashCode}',
              title: label,
              preview: label,
              themes: [label],
              kindLabel: 'Keşif',
            ),
          );
          return;
        }
        OraclyNavigationService.openChat(context);
      case DiscoveryRecommendedFeature.tarot:
        OraclyNavigationService.startTarotFlow(context);
      case DiscoveryRecommendedFeature.starMap:
        OraclyNavigationService.openStarMap(context);
      case DiscoveryRecommendedFeature.coffee:
        OraclyNavigationService.openCoffee(context);
      case DiscoveryRecommendedFeature.palm:
        OraclyNavigationService.openPalm(context);
      case DiscoveryRecommendedFeature.astrology:
        OraclyNavigationService.openAstrology(context);
      case DiscoveryRecommendedFeature.dailyMessage:
        OraclyNavigationService.openDailyMessage(context);
    }
  }
}
