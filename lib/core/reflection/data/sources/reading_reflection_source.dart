/// RC-010 — Reading/journal/ritual source via intelligence layer.
library;

import '../../../intelligence/services/intelligence_layer_service.dart';
import '../../domain/sources/reflection_source.dart';

class ReadingReflectionSource implements ReflectionSource {
  ReadingReflectionSource(this._intelligence);

  final IntelligenceLayerService _intelligence;

  @override
  ReflectionSourceKind get kind => ReflectionSourceKind.readings;

  @override
  Future<ReflectionInputPartial?> collect({required DateTime asOf}) async {
    final readings = await _intelligence.readings();
    final reflections = await _intelligence.reflections();
    final favoriteCards = await _intelligence.favoriteCards();
    final ritualDays = await _intelligence.ritualHistory();

    if (readings.isEmpty &&
        reflections.isEmpty &&
        favoriteCards.isEmpty &&
        ritualDays.isEmpty) {
      return null;
    }

    return ReflectionInputPartial(
      readings: readings,
      reflections: reflections,
      favoriteCards: favoriteCards,
      ritualDays: ritualDays,
    );
  }
}
