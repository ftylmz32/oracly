/// Opens the existing feature screen for a journal row. No duplicated logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import '../../ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import '../../coffee/presentation/reference/coffee_reference_screen.dart';
import '../../coffee/providers/coffee_providers.dart';
import '../../dream/data/dream_record_mapper.dart';
import '../../dream/providers/dream_providers.dart';
import '../../favorite_moments/copy/favorite_moments_copy.dart';
import '../../palm/presentation/palm_reference_screen.dart';
import '../../palm/providers/palm_providers.dart';
import '../../premium/providers/soul_mate_saved_provider.dart';
import '../../premium/services/soul_mate_journal_link.dart';
import '../../premium/services/soul_mate_navigation.dart';
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
        await _openCoffee(context, ref, entry.id);
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
        await _openPalm(context, ref, entry.id);
      case DiscoveryJournalKind.astrology:
        OraclyNavigationService.openAstrology(context);
      case DiscoveryJournalKind.starMap:
        OraclyNavigationService.openStarMap(context);
      case DiscoveryJournalKind.dailyMessage:
        OraclyNavigationService.openDailyMessage(context);
      case DiscoveryJournalKind.soulMate:
        await _openSoulMate(context, ref, entry.id);
    }
  }

  static Future<void> _openDream(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final record = await ref.read(dreamRepositoryProvider).getById(id);
    if (!context.mounted) return;
    if (record == null) {
      // dreamAnalysisControllerProvider is a long-lived singleton — pushing
      // the Dream screen without a match would silently show whatever dream
      // was last analyzed instead of the tapped entry. Fail honest instead.
      OraclySnackBar.show(context, message: FavoriteMomentsCopy.sourceUnavailable);
      return;
    }
    ref
        .read(dreamAnalysisControllerProvider)
        .openSaved(DreamRecordMapper.fromRecord(record));
    if (!context.mounted) return;
    OraclyNavigationService.openDream(context);
  }

  static Future<void> _openCoffee(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    // coffeeReadingControllerProvider is a long-lived singleton — pushing
    // the screen without a store match would silently show whatever coffee
    // reading was last opened/analyzed instead of the tapped entry.
    final reading = ref.read(coffeeReadingStoreProvider).byId(id);
    if (reading == null) {
      OraclySnackBar.show(context, message: FavoriteMomentsCopy.sourceUnavailable);
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: CoffeeReferenceScreen(savedReadingId: id),
      ),
    );
  }

  static Future<void> _openPalm(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    // palmReadingControllerProvider is a long-lived singleton — same
    // stale-data risk as coffee above.
    final reading = ref.read(palmReadingStoreProvider).byId(id);
    if (reading == null) {
      OraclySnackBar.show(context, message: FavoriteMomentsCopy.sourceUnavailable);
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: PalmReferenceScreen(savedReadingId: id),
      ),
    );
  }

  static Future<void> _openSoulMate(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final loaded =
        await ref.read(soulMateResultServiceProvider).latestWithPortrait();
    if (!context.mounted) return;
    final meta = loaded?.meta;
    if (!SoulMateJournalLink.canReopen(
      savedId: meta?.id,
      entryId: id,
      authoritative: meta?.hasAuthoritativeInterpretation == true,
      hasPortraitBytes: loaded != null && loaded.bytes.isNotEmpty,
    )) {
      OraclySnackBar.show(context, message: FavoriteMomentsCopy.sourceUnavailable);
      return;
    }
    SoulMateNavigation.open(context);
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
    if (!context.mounted) return;
    if (match == null) {
      // Same honest fail-open used by Dream/Coffee/Palm above — a tapped
      // journal row with no backing reading must say so, not do nothing.
      OraclySnackBar.show(context, message: FavoriteMomentsCopy.sourceUnavailable);
      return;
    }
    await Navigator.of(context).push(
      historyDetailRoute(entry: ReadingHistoryMapper.fromModel(match)),
    );
  }
}
