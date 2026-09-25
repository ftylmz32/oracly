/// Persist + memory write helpers for birth chart experience.
library;

import '../../../core/data/repositories/local_birth_chart_repository.dart';
import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_factory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../data/birth_chart_record_mapper.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_fidelity.dart';
import 'birth_chart_persistence_validator.dart';
import 'chart_calculation_port.dart';
import 'chart_insight_generator.dart';

class BirthChartExperiencePersist {
  const BirthChartExperiencePersist({
    required this._repository,
    required this._calculator,
    required this._insights,
    this._memory,
  });

  final BirthChartRepository _repository;
  final ChartCalculationPort _calculator;
  final ChartInsightGenerator _insights;
  final OraclyMemoryStore? _memory;

  Future<BirthChart> buildAndSave(BirthProfile profile) async {
    String? previousSourceId;
    try {
      previousSourceId = (await _repository.getLatest())?.id;
    } on BirthChartOwnerUnavailableException {
      rethrow;
    } catch (_) {}
    var chart = _calculator.calculate(profile);
    final insights = _insights.generate(chart);
    final themes = _insights.lifeThemes(chart);
    final full = chart.fidelity == ChartCalculationFidelity.fullNatalEphemeris;
    chart = BirthChart(
      id: chart.id,
      profile: chart.profile,
      sun: chart.sun,
      moon: full ? chart.moon : null,
      rising: full ? chart.rising : null,
      midheaven: full ? chart.midheaven : null,
      planets: full ? chart.planets : const [],
      houses: full ? chart.houses : const [],
      aspects: full ? chart.aspects : const [],
      elementBalance: chart.elementBalance,
      dominantEnergy: chart.dominantEnergy,
      lifeThemes: themes,
      insights: insights,
      generatedAt: chart.generatedAt,
      precision: chart.precision,
      fidelity: chart.fidelity,
      natalEvidence: chart.natalEvidence,
    );
    if (!BirthChartPersistenceValidator.isJourneyReady(chart)) {
      throw StateError('Birth chart interpretation is incomplete');
    }
    await _repository.save(BirthChartRecordMapper.toRecord(chart));
    await writeMemory(chart, supersededSourceId: previousSourceId);
    return chart;
  }

  Future<void> writeMemory(
    BirthChart chart, {
    String? supersededSourceId,
  }) async {
    final memory = _memory;
    if (memory == null ||
        !BirthChartPersistenceValidator.isJourneyReady(chart)) {
      return;
    }
    if (supersededSourceId != null && supersededSourceId != chart.id) {
      try {
        await memory.removeBySourceAndType(
          supersededSourceId,
          OraclyReadingType.birthChart,
        );
      } catch (_) {}
    }
    try {
      await memory.upsert(OraclyMemoryFactory.birthChart(chart));
    } catch (_) {}
  }
}
