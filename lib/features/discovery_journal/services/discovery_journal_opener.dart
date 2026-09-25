/// Opens the existing feature screen for a journal row. No duplicated logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../copy/discovery_journal_copy.dart';
import '../models/discovery_journal_entry.dart';
import '../models/discovery_journal_kind.dart';
import 'discovery_journal_open_helpers.dart';
import 'discovery_journal_star_map_open.dart';

abstract final class DiscoveryJournalOpener {
  DiscoveryJournalOpener._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    DiscoveryJournalEntry entry,
  ) async {
    switch (entry.kind) {
      case DiscoveryJournalKind.tarot:
        await DiscoveryJournalOpenHelpers.openTarot(context, ref, entry.id);
      case DiscoveryJournalKind.dream:
        await DiscoveryJournalOpenHelpers.openDream(context, ref, entry.id);
      case DiscoveryJournalKind.coffee:
        await DiscoveryJournalOpenHelpers.openCoffee(context, ref, entry.id);
      case DiscoveryJournalKind.companion:
        openOracleConversation(
          context,
          readingContext: OracleReadingContextSources.discoveryJournal(
            id: entry.id,
            title: entry.title,
            preview: entry.preview,
            themes: entry.themes,
            kindLabel: DiscoveryJournalCopy.badgeCompanion,
          ),
        );
      case DiscoveryJournalKind.palm:
        await DiscoveryJournalOpenHelpers.openPalm(context, ref, entry.id);
      case DiscoveryJournalKind.astrology:
        OraclyNavigationService.openAstrology(context);
      case DiscoveryJournalKind.starMap:
        await DiscoveryJournalStarMapOpen.open(context, ref, entry.id);
      case DiscoveryJournalKind.dailyMessage:
        OraclyNavigationService.openDailyMessage(context);
      case DiscoveryJournalKind.soulMate:
        await DiscoveryJournalOpenHelpers.openSoulMate(context, ref, entry.id);
    }
  }
}
