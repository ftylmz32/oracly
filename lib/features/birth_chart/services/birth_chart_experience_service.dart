/// Birth chart orchestrator — persist profile, calculate via port, interpret.
library;

import '../../../core/data/repositories/local_birth_chart_repository.dart';
import '../../../core/domain/models/birth_chart_record.dart';
import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../data/birth_chart_record_mapper.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import 'birth_chart_experience_persist.dart';
import 'birth_chart_load_result.dart';
import 'birth_chart_persistence_validator.dart';
import 'chart_calculation_port.dart';
import 'chart_insight_generator.dart';
import 'natal_chart_calculator.dart';

export 'birth_chart_load_result.dart';

class BirthChartExperienceService {
  BirthChartExperienceService({
    required BirthChartRepository repository,
    ChartCalculationPort? calculator,
    ChartInsightGenerator? insightGenerator,
    OraclyMemoryStore? memory,
  }) : _repository = repository,
       _memory = memory,
       _persist = BirthChartExperiencePersist(
         repository: repository,
         calculator: calculator ?? const NatalChartCalculator(),
         insights: insightGenerator ?? const ChartInsightGenerator(),
         memory: memory,
       ),
       _calculator = calculator ?? const NatalChartCalculator();

  final BirthChartRepository _repository;
  final OraclyMemoryStore? _memory;
  final BirthChartExperiencePersist _persist;
  final ChartCalculationPort _calculator;

  Future<BirthChartExperienceResult> generate(BirthProfile profile) async {
    final chart = await _persist.buildAndSave(profile);
    return BirthChartExperienceResult(chart: chart);
  }

  Future<BirthChartLoadResult> loadSaved() async {
    BirthChartRecord? record;
    try {
      record = await _repository.getLatest();
    } on BirthChartOwnerUnavailableException {
      return const BirthChartLoadResult.ownerUnavailable();
    }
    if (record == null) return const BirthChartLoadResult.none();

    BirthChart chart;
    try {
      chart = BirthChartRecordMapper.fromRecord(record);
    } catch (_) {
      await clearSavedData();
      return const BirthChartLoadResult.clearedCorrupt();
    }

    try {
      if (_needsRebuild(chart) ||
          !BirthChartPersistenceValidator.isJourneyReady(chart)) {
        chart = await _persist.buildAndSave(chart.profile);
      }
    } on BirthChartOwnerUnavailableException {
      return const BirthChartLoadResult.ownerUnavailable();
    } catch (_) {
      final profile = chart.profile;
      await clearSavedData();
      return BirthChartLoadResult.clearedCorrupt(profileHint: profile);
    }

    if (!BirthChartPersistenceValidator.isJourneyReady(chart)) {
      final profile = chart.profile;
      await clearSavedData();
      return BirthChartLoadResult.clearedCorrupt(profileHint: profile);
    }

    await _persist.writeMemory(chart);
    return BirthChartLoadResult.loaded(chart);
  }

  Future<void> clearSavedData() async {
    String? sourceId;
    try {
      sourceId = (await _repository.getLatest())?.id;
    } on BirthChartOwnerUnavailableException {
      rethrow;
    } catch (_) {}
    await _repository.clearLatest();
    if (sourceId != null) {
      try {
        await _memory?.removeBySourceAndType(
          sourceId,
          OraclyReadingType.birthChart,
        );
      } catch (_) {}
    }
  }

  Future<BirthChart?> loadSavedChart() async {
    final result = await loadSaved();
    return result.chart;
  }

  Future<BirthChart> ensureChartReady(BirthChart chart) async {
    if (BirthChartPersistenceValidator.isJourneyReady(chart) &&
        !_needsRebuild(chart)) {
      await _persist.writeMemory(chart);
      return chart;
    }
    return _persist.buildAndSave(chart.profile);
  }

  bool _needsRebuild(BirthChart chart) {
    if (chart.fidelity != _calculator.fidelity) return true;
    if (chart.hasFullNatal) return false;
    if (chart.precision == ChartPrecision.full) return true;
    return chart.moon != null ||
        chart.rising != null ||
        chart.planets.isNotEmpty ||
        chart.houses.isNotEmpty ||
        chart.aspects.isNotEmpty;
  }
}
