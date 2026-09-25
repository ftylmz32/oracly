/// Feature open helpers for Keşif Günlüğü rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../../shared/ui/oracly_snackbar.dart';
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

abstract final class DiscoveryJournalOpenHelpers {
  DiscoveryJournalOpenHelpers._();

  static Future<void> openDream(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final record = await ref.read(dreamRepositoryProvider).getById(id);
    if (!context.mounted) return;
    if (record == null) {
      OraclySnackBar.show(
        context,
        message: FavoriteMomentsCopy.sourceUnavailable,
      );
      return;
    }
    ref
        .read(dreamAnalysisControllerProvider)
        .openSaved(DreamRecordMapper.fromRecord(record));
    if (!context.mounted) return;
    OraclyNavigationService.openDream(context);
  }

  static Future<void> openCoffee(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final reading = ref.read(coffeeReadingStoreProvider).byId(id);
    if (reading == null) {
      OraclySnackBar.show(
        context,
        message: FavoriteMomentsCopy.sourceUnavailable,
      );
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: CoffeeReferenceScreen(savedReadingId: id),
      ),
    );
  }

  static Future<void> openPalm(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final reading = ref.read(palmReadingStoreProvider).byId(id);
    if (reading == null) {
      OraclySnackBar.show(
        context,
        message: FavoriteMomentsCopy.sourceUnavailable,
      );
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: PalmReferenceScreen(savedReadingId: id),
      ),
    );
  }

  static Future<void> openSoulMate(
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
      OraclySnackBar.show(
        context,
        message: FavoriteMomentsCopy.sourceUnavailable,
      );
      return;
    }
    SoulMateNavigation.open(context);
  }

  static Future<void> openTarot(
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
      OraclySnackBar.show(
        context,
        message: FavoriteMomentsCopy.sourceUnavailable,
      );
      return;
    }
    await Navigator.of(context).push(
      historyDetailRoute(entry: ReadingHistoryMapper.fromModel(match)),
    );
  }
}
