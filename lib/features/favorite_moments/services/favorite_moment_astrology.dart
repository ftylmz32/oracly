/// Astrology favorite drafts.
library;

import '../../astrology/models/astrology_daily_reading.dart';
import '../models/favorite_moment.dart';
import 'favorite_moment_text.dart';

abstract final class FavoriteMomentAstrology {
  FavoriteMomentAstrology._();

  static FavoriteMoment fromDaily({
    required String signId,
    required DateTime at,
    required String signLabel,
    required AstrologyDailyReading reading,
  }) {
    final ref = '$signId-${at.year}-${at.month}-${at.day}';
    return FavoriteMoment(
      id: '${FavoriteMomentSource.astrology.name}:$ref',
      source: FavoriteMomentSource.astrology,
      sourceRef: ref,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.firstNonEmpty([
        reading.overall,
        reading.advice,
        reading.innerTheme,
      ]),
      visualLabel: signLabel,
    );
  }
}
