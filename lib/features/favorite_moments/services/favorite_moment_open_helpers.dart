/// Tarot + snapshot fallback helpers for favorite open.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../../shared/ui/oracly_snackbar.dart';
import '../../tarot/presentation/screens/reading_history_detail_screen.dart';
import '../../tarot/presentation/utils/reading_history_mapper.dart';
import '../copy/favorite_moments_copy.dart';
import '../models/favorite_moment.dart';
import '../presentation/screens/favorite_moment_snapshot_screen.dart';
import 'favorite_moment_snapshot.dart';

abstract final class FavoriteMomentOpenHelpers {
  FavoriteMomentOpenHelpers._();

  static Future<void> openTarot(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    final readings = await ref.read(historyServiceProvider).getAll();
    ReadingModel? match;
    for (final reading in readings) {
      if (reading.id == moment.sourceRef ||
          reading.sessionId == moment.sourceRef) {
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
    showUnavailable(context);
  }

  static Future<void> openFallback(
    BuildContext context,
    FavoriteMoment moment,
  ) async {
    if (!FavoriteMomentSnapshot.canShowFallback(moment)) {
      showUnavailable(context);
      return;
    }
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: FavoriteMomentSnapshotScreen(moment: moment),
      ),
    );
  }

  static void showUnavailable(BuildContext context) {
    OraclySnackBar.show(
      context,
      message: FavoriteMomentsCopy.sourceUnavailable,
    );
  }
}
