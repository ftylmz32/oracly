/// RC-010 — Extensible reflection source contract.
library;

import '../../../domain/models/reading.dart';
import '../../../intelligence/domain/models/favorite_card_ref.dart';
import '../../../intelligence/domain/models/reflection_entry.dart';
import '../../../intelligence/domain/models/ritual_history_entry.dart';
import '../models/reflection_input.dart';

/// Future modules (Dream, Astrology, Numerology, Moon Rituals) implement this.
enum ReflectionSourceKind {
  readings,
  dream,
  astrology,
  numerology,
  moonRitual,
  companion,
}

abstract class ReflectionSource {
  ReflectionSourceKind get kind;

  /// Returns partial input or null when the source has no stored data yet.
  Future<ReflectionInputPartial?> collect({required DateTime asOf});
}

/// Partial contribution merged into [ReflectionInput] by the engine service.
class ReflectionInputPartial {
  const ReflectionInputPartial({
    this.readings = const [],
    this.reflections = const [],
    this.favoriteCards = const [],
    this.ritualDays = const [],
  });

  final List<ReadingModel> readings;
  final List<ReflectionEntry> reflections;
  final List<FavoriteCardRef> favoriteCards;
  final List<RitualHistoryEntry> ritualDays;

  ReflectionInputPartial merge(ReflectionInputPartial other) {
    return ReflectionInputPartial(
      readings: [...readings, ...other.readings],
      reflections: [...reflections, ...other.reflections],
      favoriteCards: [...favoriteCards, ...other.favoriteCards],
      ritualDays: [...ritualDays, ...other.ritualDays],
    );
  }
}
