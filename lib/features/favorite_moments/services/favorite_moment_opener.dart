/// Opens the source feature for a saved moment.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/navigation/oracly_page_transitions.dart';
import '../../coffee/providers/coffee_providers.dart';
import '../../dream/data/dream_record_mapper.dart';
import '../../dream/providers/dream_providers.dart';
import '../../palm/presentation/palm_reference_screen.dart';
import '../../tarot/presentation/screens/reading_history_detail_screen.dart';
import '../../tarot/presentation/utils/reading_history_mapper.dart';
import '../models/favorite_moment.dart';

abstract final class FavoriteMomentOpener {
  FavoriteMomentOpener._();

  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    FavoriteMoment moment,
  ) async {
    switch (moment.source) {
      case FavoriteMomentSource.tarot:
        await _openTarot(context, ref, moment.sourceRef);
      case FavoriteMomentSource.coffee:
        await _openCoffee(context, ref, moment.sourceRef);
      case FavoriteMomentSource.palm:
        await _openPalm(context, moment.sourceRef);
      case FavoriteMomentSource.dream:
        await _openDream(context, ref, moment.sourceRef);
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
    String id,
  ) async {
    final reading =
        ref.read(coffeeExperienceServiceProvider).savedById(id);
    if (reading != null) {
      ref.read(coffeeReadingControllerProvider).openSaved(reading);
    }
    OraclyNavigationService.openCoffee(context);
  }

  static Future<void> _openPalm(BuildContext context, String id) async {
    await Navigator.of(context).push(
      OraclyPageTransitions.fade(
        page: PalmReferenceScreen(savedReadingId: id),
      ),
    );
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
