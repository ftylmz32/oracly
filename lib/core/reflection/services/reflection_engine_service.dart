/// RC-010 — Reflection engine facade — consumes intelligence layer, not AI.
library;

import '../../intelligence/services/intelligence_layer_service.dart';
import '../domain/models/reflection_input.dart';
import '../domain/models/reflection_summary.dart';
import '../domain/sources/reflection_source.dart';
import '../engine/reflection_engine.dart';

/// Shared entry point for Home, Reading, Chat, Journal, and future modules.
class ReflectionEngineService {
  ReflectionEngineService({
    required IntelligenceLayerService intelligence,
    ReflectionEngine engine = const ReflectionEngine(),
    List<ReflectionSource> sources = const [],
  })  : _intelligence = intelligence,
        _engine = engine,
        _sources = sources;

  final IntelligenceLayerService _intelligence;
  final ReflectionEngine _engine;
  final List<ReflectionSource> _sources;

  Future<ReflectionSummary> analyze({DateTime? asOf}) async {
    final input = await _buildInput(asOf ?? DateTime.now());
    return _engine.analyze(input);
  }

  ReflectionSummary analyzeInput(ReflectionInput input) => _engine.analyze(input);

  Future<ReflectionInput> buildInput({DateTime? asOf}) =>
      _buildInput(asOf ?? DateTime.now());

  Future<ReflectionInput> _buildInput(DateTime asOf) async {
    if (_sources.isEmpty) {
      return ReflectionInput(
        readings: await _intelligence.readings(),
        reflections: await _intelligence.reflections(),
        favoriteCards: await _intelligence.favoriteCards(),
        ritualDays: await _intelligence.ritualHistory(),
        asOf: asOf,
      );
    }

    ReflectionInputPartial? merged;
    for (final source in _sources) {
      final partial = await source.collect(asOf: asOf);
      if (partial == null) continue;
      merged = merged == null ? partial : merged.merge(partial);
    }

    merged ??= ReflectionInputPartial(
      readings: await _intelligence.readings(),
      reflections: await _intelligence.reflections(),
      favoriteCards: await _intelligence.favoriteCards(),
      ritualDays: await _intelligence.ritualHistory(),
    );

    return ReflectionInput(
      readings: merged.readings,
      reflections: merged.reflections,
      favoriteCards: merged.favoriteCards,
      ritualDays: merged.ritualDays,
      asOf: asOf,
    );
  }
}
