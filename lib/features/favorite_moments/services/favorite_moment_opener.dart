/// Opens the source feature for a saved moment.
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
import '../../palm/providers/palm_providers.dart';
import '../../palm/presentation/palm_reference_screen.dart';
import '../../tarot/presentation/screens/reading_history_detail_screen.dart';
import '../../tarot/presentation/utils/reading_history_mapper.dart';
import '../copy/favorite_moments_copy.dart';
import '../models/favorite_moment.dart';
import '../presentation/screens/favorite_moment_snapshot_screen.dart';
import 'favorite_moment_snapshot.dart';

abstract final class FavoriteMomentOpener {
  FavoriteMomentOpener._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    switch (moment.source) {
      case FavoriteMomentSource.tarot:
        await _openTarot(context, ref, moment);
      case FavoriteMomentSource.coffee:
        await _openCoffee(context, ref, moment);
      case FavoriteMomentSource.palm:
        await _openPalm(context, ref, moment);
      case FavoriteMomentSource.dream:
        await _openDream(context, ref, moment);
      case FavoriteMomentSource.companion:
        OraclyNavigationService.openChat(context);
      case FavoriteMomentSource.dailyMessage:
        OraclyNavigationService.openDailyMessage(context);
      case FavoriteMomentSource.starMap:
        OraclyNavigationService.openStarMap(context);
      case FavoriteMomentSource.astrology:
        OraclyNavigationService.openAstrology(context);
    }
  }

  static Future<void> _openCoffee(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    final reading = ref.read(coffeeReadingStoreProvider).byId(moment.sourceRef);
    if (reading != null) {
      await Navigator.of(context).push(
        OraclyPageTransitions.fade(
          page: CoffeeReferenceScreen(savedReadingId: moment.sourceRef),
        ),
      );
      return;
    }
    await _openFallback(context, moment);
  }

  static Future<void> _openPalm(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    final reading = ref.read(palmReadingStoreProvider).byId(moment.sourceRef);
    if (reading != null) {
      await Navigator.of(context).push(
        OraclyPageTransitions.fade(
          page: PalmReferenceScreen(savedReadingId: moment.sourceRef),
        ),
      );
      return;
    }
    await _openFallback(context, moment);
  }

  static Future<void> _openDream(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    final record = await ref.read(dreamRepositoryProvider).getById(moment.sourceRef);
    if (record != null) {
      ref
          .read(dreamAnalysisControllerProvider)
          .openSaved(DreamRecordMapper.fromRecord(record));
      if (!context.mounted) return;
      OraclyNavigationService.openDream(context);
      return;
    }
    if (!context.mounted) return;
    await _openFallback(context, moment);
  }

  static Future<void> _openTarot(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    final readings = await ref.read(historyServiceProvider).getAll();
    ReadingModel? match;
    for (final reading in readings) {
      if (reading.id == moment.sourceRef || reading.sessionId == moment.sourceRef) {
        match = reading;
        break;
      }
    }
    if (match != null && context.mounted) {
      await Navigator.of(context).push(
        historyDetailRoute(entry: ReadingHistoryMapper.fromModel(match)),
      );
      return;
    }
    final entry = FavoriteMomentSnapshot.tarotHistoryEntry(moment);
    if (entry != null && context.mounted) {
      await Navigator.of(context).push(historyDetailRoute(entry: entry));
      return;
    }
    if (!context.mounted) return;
    _showUnavailable(context);
  }

  static Future<void> _openFallback(
    BuildContext context,
    FavoriteMoment moment,
  ) async {
    if (!FavoriteMomentSnapshot.canShowFallback(moment)) {
      _showUnavailable(context);
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: FavoriteMomentSnapshotScreen(moment: moment),
      ),
    );
  }

  static void _showUnavailable(BuildContext context) {
    OraclySnackBar.show(
      context,
      message: FavoriteMomentsCopy.sourceUnavailable,
    );
  }
}
