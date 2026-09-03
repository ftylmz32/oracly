/// Snapshot fallback when privacy clear removed the source record.
library;

import 'package:flutter/material.dart';

import '../../tarot/presentation/widgets/reading_history/reading_history_data.dart';
import '../models/favorite_moment.dart';

abstract final class FavoriteMomentSnapshot {
  FavoriteMomentSnapshot._();

  static bool canShowFallback(FavoriteMoment moment) {
    return switch (moment.source) {
      FavoriteMomentSource.tarot => _hasTarotVisual(moment),
      FavoriteMomentSource.dream ||
      FavoriteMomentSource.coffee ||
      FavoriteMomentSource.palm =>
        moment.quote.trim().isNotEmpty,
      _ => moment.quote.trim().isNotEmpty,
    };
  }

  static ReadingHistoryEntry? tarotHistoryEntry(FavoriteMoment moment) {
    if (!_hasTarotVisual(moment)) return null;
    return ReadingHistoryEntry(
      id: moment.sourceRef,
      date: moment.occurredAt,
      spreadType: 'Tek Kart',
      filter: HistorySpreadFilter.single,
      cardName: moment.visualLabel!.trim(),
      cardImageAsset: moment.visualAsset!.trim(),
      aiSummary: moment.quote,
      moodIcon: Icons.auto_awesome_rounded,
      cardIndex: 0,
      heroTag: 'favorite_tarot_',
      isFavorite: true,
      isReversed: moment.visualIsReversed,
    );
  }

  static bool _hasTarotVisual(FavoriteMoment moment) {
    final asset = moment.visualAsset?.trim();
    final label = moment.visualLabel?.trim();
    return asset != null &&
        asset.isNotEmpty &&
        label != null &&
        label.isNotEmpty;
  }
}
