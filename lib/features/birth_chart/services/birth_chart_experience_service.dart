/// Birth chart orchestrator — persist profile, calculate via port, interpret.
library;

import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/memory/oracly_memory.dart';
import '../../../core/memory/oracly_memory_factory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../data/birth_chart_record_mapper.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import 'birth_chart_persistence_validator.dart';
import 'chart_calculation_port.dart';
import 'chart_insight_generator.dart';
import 'natal_chart_calculator.dart';

class BirthChartExperienceResult {
  const BirthChartExperienceResult({required this.chart});

  final BirthChart chart;
}

enum BirthChartLoadStatus { none, loaded, clearedCorrupt }

class BirthChartLoadResult {
  const BirthChartLoadResult._({
    required this.status,
    this.chart,
    this.profileHint,
  });

  const BirthChartLoadResult.none() : this._(status: BirthChartLoadStatus.none);

  const BirthChartLoadResult.loaded(BirthChart chart)
    : this._(status: BirthChartLoadStatus.loaded, chart: chart);

  const BirthChartLoadResult.clearedCorrupt({BirthProfile? profileHint})
    : this._(
        status: BirthChartLoadStatus.clearedCorrupt,
        profileHint: profileHint,
      );

  final BirthChartLoadStatus status;
  final BirthChart? chart;
  final BirthProfile? profileHint;
}

class BirthChartExperienceService {
  BirthChartExperienceService({
    required this._repository,
    ChartCalculationPort? calculator,
    ChartInsightGenerator? insightGenerator,
    this._memory,
  }) : _calculator = calculator ?? const NatalChartCalculator(),
       _insights = insightGenerator ?? const ChartInsightGenerator();

  final BirthChartRepository _repository;
  final ChartCalculationPort _calculator;
  final ChartInsightGenerator _insights;
  final OraclyMemoryStore? _memory;

  Future<BirthChartExperienceResult> generate(BirthProfile profile) async {
    final chart = await _buildAndSave(profile);
    return BirthChartExperienceResult(chart: chart);
  }

  Future<BirthChartLoadResult> loadSaved() async {
    final record = await _repository.getLatest();
    if (record == null) return const BirthChartLoadResult.none();

    BirthChart chart;
    try {
      chart = BirthChartRecordMapper.fromRecord(record);
    } catch (_) {
      await clearSavedData();
      return const BirthChartLoadResult.clearedCorrupt();
    }

    try {
      if (_needsRebuild(chart)) {
        chart = await _buildAndSave(chart.profile);
      } else if (!BirthChartPersistenceValidator.isJourneyReady(chart)) {
        chart = await _buildAndSave(chart.profile);
      }
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

    await _writeMemory(chart);

    return BirthChartLoadResult.loaded(chart);
  }

  Future<void> clearSavedData() async {
    String? sourceId;
    try {
      sourceId = (await _repository.getLatest())?.id;
    } catch (_) {}
    await _repository.clearLatest();
    if (sourceId != null) {
      try {
        await _memory?.removeBySourceAndType(
          sourceId,
          OraclyReadingType.birthChart,
        );
      } catch (_) {
        // Connected memory is an optional index; source deletion still wins.
      }
    }
  }

  Future<BirthChart?> loadSavedChart() async {
    final result = await loadSaved();
    return result.chart;
  }

  Future<BirthChart> ensureChartReady(BirthChart chart) async {
    if (BirthChartPersistenceValidator.isJourneyReady(chart) &&
        !_needsRebuild(chart)) {
      await _writeMemory(chart);
      return chart;
    }
    return _buildAndSave(chart.profile);
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

  Future<BirthChart> _buildAndSave(BirthProfile profile) async {
    String? previousSourceId;
    try {
      previousSourceId = (await _repository.getLatest())?.id;
    } catch (_) {}
    var chart = _calculator.calculate(profile);
    final insights = _insights.generate(chart);
    final themes = _insights.lifeThemes(chart);
    chart = BirthChart(
      id: chart.id,
      profile: chart.profile,
      sun: chart.sun,
      moon: chart.hasFullNatal ? chart.moon : null,
      rising: chart.hasFullNatal ? chart.rising : null,
      planets: chart.hasFullNatal ? chart.planets : const [],
      houses: chart.hasFullNatal ? chart.houses : const [],
      aspects: chart.hasFullNatal ? chart.aspects : const [],
      elementBalance: chart.elementBalance,
      dominantEnergy: chart.dominantEnergy,
      lifeThemes: themes,
      insights: insights,
      generatedAt: chart.generatedAt,
      precision: chart.precision,
      fidelity: chart.fidelity,
    );
    if (!BirthChartPersistenceValidator.isJourneyReady(chart)) {
      throw StateError('Birth chart interpretation is incomplete');
    }
    await _repository.save(BirthChartRecordMapper.toRecord(chart));
    await _writeMemory(chart, supersededSourceId: previousSourceId);
    return chart;
  }

  Future<void> _writeMemory(
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
    } catch (_) {
      // Result persistence is authoritative and must remain available.
    }
  }
}
