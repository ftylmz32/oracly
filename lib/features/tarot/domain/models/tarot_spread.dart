/// OR-1000 — Tarot spread domain model.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/l10n.dart';

/// Supported spread types for the ritual flow.
enum TarotSpreadType {
  single(1),
  threeCard(3),
  fiveCard(5),
  sevenCard(7),
  celticCross(10);

  const TarotSpreadType(this.cardCount);

  final int cardCount;

  /// Locale-aware display title (also used when persisting spreadType).
  String get label => OraclyL10n.t('tarot.spread.$name');

  static TarotSpreadType? fromTitle(String title) {
    final raw = title.trim();
    if (raw.isEmpty) return null;
    for (final spread in values) {
      if (spread.name == raw) return spread;
      if (OraclyL10n.t('tarot.spread.${spread.name}', languageCode: 'tr') ==
              raw ||
          OraclyL10n.t('tarot.spread.${spread.name}', languageCode: 'en') ==
              raw ||
          OraclyL10n.t('tarot.spread.${spread.name}', languageCode: 'ru') ==
              raw) {
        return spread;
      }
    }
    return switch (raw.toLowerCase()) {
      'tek kart' || 'one card' || 'одна карта' => TarotSpreadType.single,
      'üç kart' ||
      'üç kart açılımı' ||
      'three cards' ||
      'three-card spread' ||
      'три карты' =>
        TarotSpreadType.threeCard,
      'beş kart' ||
      'five cards' ||
      'пять карт' ||
      'derin açılım' ||
      'deep spread' ||
      'глубокий расклад' =>
        TarotSpreadType.fiveCard,
      'yedi kart' ||
      'seven card' ||
      'seven' ||
      'seven cards' ||
      'семь карт' =>
        TarotSpreadType.sevenCard,
      'celtic cross' ||
      'kelt haçı' ||
      'кельтский крест' =>
        TarotSpreadType.celticCross,
      _ => null,
    };
  }
}

/// User intention captured before the shuffle.
@immutable
class TarotIntention {
  const TarotIntention({
    required this.text,
    this.topic,
  });

  final String text;
  final String? topic;

  bool get isEmpty => text.trim().isEmpty;
}

/// How the next cards leave the shuffled pile.
enum TarotDrawMode {
  manual,
  orDraw,
}
