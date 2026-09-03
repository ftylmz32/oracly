/// Tarot favorite drafts - preserve drawn-card orientation.
library;

import '../../../core/domain/models/reading.dart';
import '../../tarot/history/tarot_history_privacy.dart';
import '../models/favorite_moment.dart';
import 'favorite_moment_text.dart';

abstract final class FavoriteMomentTarot {
  FavoriteMomentTarot._();

  static FavoriteMoment fromReading(ReadingModel reading) {
    final ref = reading.id;
    return FavoriteMoment(
      id: '${FavoriteMomentSource.tarot.name}:$ref',
      source: FavoriteMomentSource.tarot,
      sourceRef: ref,
      savedAt: DateTime.now(),
      occurredAt: reading.createdAt,
      quote: TarotHistoryPrivacy.shortInsight(reading),
      visualAsset: reading.cardImageAsset,
      visualLabel: reading.cardName,
      visualIsReversed: reading.primaryIsReversed,
    );
  }

  static FavoriteMoment fromLive({
    required String sessionId,
    required DateTime at,
    required String cardName,
    required String cardAsset,
    required String insight,
    bool isReversed = false,
  }) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.tarot.name}:$sessionId',
      source: FavoriteMomentSource.tarot,
      sourceRef: sessionId,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.clip(insight),
      visualAsset: cardAsset,
      visualLabel: cardName,
      visualIsReversed: isReversed,
    );
  }
}
