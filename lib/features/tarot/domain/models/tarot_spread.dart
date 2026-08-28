/// OR-1000 — Tarot spread domain model.
library;

import 'package:flutter/foundation.dart';

/// Supported spread types for the ritual flow.
enum TarotSpreadType {
  single('Tek Kart', 1),
  threeCard('Üç Kart', 3),
  fiveCard('Derin Açılım', 5),
  sevenCard('Yedi Kart', 7),
  celticCross('Kelt Haçı', 10);

  const TarotSpreadType(this.label, this.cardCount);

  final String label;
  final int cardCount;

  static TarotSpreadType? fromTitle(String title) {
    for (final spread in values) {
      if (spread.label == title) return spread;
    }
    return switch (title.toLowerCase()) {
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
