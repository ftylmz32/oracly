/// RC-010 — Normalized engine input from intelligence layer sources.
library;

import '../../../domain/models/reading.dart';
import '../../../intelligence/domain/models/favorite_card_ref.dart';
import '../../../intelligence/domain/models/reflection_entry.dart';
import '../../../intelligence/domain/models/ritual_history_entry.dart';

class ReflectionInput {
  const ReflectionInput({
    required this.readings,
    required this.reflections,
    required this.favoriteCards,
    required this.ritualDays,
    required this.asOf,
  });

  final List<ReadingModel> readings;
  final List<ReflectionEntry> reflections;
  final List<FavoriteCardRef> favoriteCards;
  final List<RitualHistoryEntry> ritualDays;
  final DateTime asOf;

  bool get isEmpty =>
      readings.isEmpty &&
      reflections.isEmpty &&
      favoriteCards.isEmpty &&
      ritualDays.isEmpty;
}
