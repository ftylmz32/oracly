/// Opens the existing feature screen for a journal row. No duplicated logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../coffee/presentation/reference/coffee_reference_screen.dart';
import '../../dream/data/dream_record_mapper.dart';
import '../../dream/providers/dream_providers.dart';
import '../../palm/presentation/palm_reference_screen.dart';
import '../../tarot/presentation/screens/reading_history_detail_screen.dart';
import '../../tarot/presentation/utils/reading_history_mapper.dart';
import '../copy/discovery_journal_copy.dart';
import '../models/discovery_journal_entry.dart';
import '../models/discovery_journal_kind.dart';

abstract final class DiscoveryJournalOpener {
  DiscoveryJournalOpener._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    DiscoveryJournalEntry entry,
  ) async {
    switch (entry.kind) {
      case DiscoveryJournalKind.tarot:
        await _openTarot(context, ref, entry.id);
      case DiscoveryJournalKind.dream:
        await _openDream(context, ref, entry.id);
      case DiscoveryJournalKind.coffee:
        await Navigator.of(context).push(
          OraclyPageTransitions.fade(
            page: CoffeeReferenceScreen(savedReadingId: entry.id),
          ),
        );
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
        await Navigator.of(context).push(
          OraclyPageTransitions.fade(
            page: PalmReferenceScreen(savedReadingId: entry.id),
          ),
        );
      case DiscoveryJournalKind.astrology:
        OraclyNavigationService.openAstrology(context);
      case DiscoveryJournalKind.starMap:
        OraclyNavigationService.openStarMap(context);
      case DiscoveryJournalKind.dailyMessage:
        OraclyNavigationService.openDailyMessage(context);
    }
  }

  static Future<void> _openDream(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final record = await ref.read(dreamRepositoryProvider).getById(id);
    if (record != null) {
      ref
          .read(dreamAnalysisControllerProvider)
          .openSaved(DreamRecordMapper.fromRecord(record));
    }
    if (!context.mounted) return;
    OraclyNavigationService.openDream(context);
  }

  static Future<void> _openTarot(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final readings = await ref.read(historyServiceProvider).getAll();
    ReadingModel? match;
    for (final reading in readings) {
      if (reading.id == id || reading.sessionId == id) {
        match = reading;
        break;
      }
    }
    if (match == null || !context.mounted) return;
    await Navigator.of(context).push(
      historyDetailRoute(entry: ReadingHistoryMapper.fromModel(match)),
    );
  }
}
