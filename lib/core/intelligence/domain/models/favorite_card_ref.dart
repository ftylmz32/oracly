/// RC-009 — Lightweight favorite card reference for cross-feature queries.
library;

class FavoriteCardRef {
  const FavoriteCardRef({
    required this.readingId,
    required this.cardName,
    required this.cardImageAsset,
    required this.favoritedAt,
  });

  final String readingId;
  final String cardName;
  final String cardImageAsset;
  final DateTime favoritedAt;
}
