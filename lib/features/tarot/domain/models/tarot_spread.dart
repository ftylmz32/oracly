/// OR-1000 — Tarot spread domain model.
library;

import 'package:flutter/foundation.dart';

/// Supported spread types for the ritual flow.
enum TarotSpreadType {
  single('Tek Kart', 1),
  threeCard('Üç Kart', 3),
  fiveCard('Beş Kart', 5),
  celticCross('Kelt Haçı', 10);

  const TarotSpreadType(this.label, this.cardCount);

  final String label;
  final int cardCount;

  static TarotSpreadType? fromTitle(String title) {
    for (final spread in values) {
      if (spread.label == title) return spread;
    }
    return switch (title.toLowerCase()) {
      'tek kart' => TarotSpreadType.single,
      'üç kart' || 'üç kart açılımı' => TarotSpreadType.threeCard,
      'beş kart' => TarotSpreadType.fiveCard,
      'celtic cross' || 'kelt haçı' => TarotSpreadType.celticCross,
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
