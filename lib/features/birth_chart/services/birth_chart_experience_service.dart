/// SPRINT-002 — Birth chart journey orchestrator.
library;

import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../features/ai/domain/models/prompts/astrology_prompt.dart';
import '../../../features/ai/domain/repositories/astrology_ai_repository.dart';
import '../data/birth_chart_record_mapper.dart';
import '../models/birth_chart.dart';
import '../models/birth_profile.dart';
import '../models/chart_insight.dart';
import 'chart_insight_generator.dart';
import 'chart_calculation_port.dart';
import 'natal_chart_calculator.dart';

class BirthChartExperienceResult {
  const BirthChartExperienceResult({required this.chart});

  final BirthChart chart;
}

class BirthChartExperienceService {
  BirthChartExperienceService({
    required BirthChartRepository repository,
    required AstrologyAIRepository aiRepository,
    ChartCalculationPort? calculator,
    ChartInsightGenerator? insightGenerator,
  })  : _repository = repository,
        _aiRepository = aiRepository,
        _calculator = calculator ?? const NatalChartCalculator(),
        _insights = insightGenerator ?? const ChartInsightGenerator();

  final BirthChartRepository _repository;
  final AstrologyAIRepository _aiRepository;
  final ChartCalculationPort _calculator;
  final ChartInsightGenerator _insights;

  Future<BirthChartExperienceResult> generate(BirthProfile profile) async {
    var chart = _calculator.calculate(profile);
    final generatedInsights = _insights.generate(chart);
    final themes = _insights.lifeThemes(chart);

    String? aiEnrichment;
    try {
      final response = await _aiRepository.consult(
        AstrologyPrompt(
          zodiacSign: chart.sun.sign.labelTr,
          question:
              'Doğum haritam için kısa, jargon az, olasılık diliyle bir özet ver.',
          birthDate: profile.birthDate,
          birthTime: profile.birthTime?.toIso8601String(),
          birthPlace: profile.birthPlace,
          personality: 'reflective',
        ),
      );
      aiEnrichment = response.text.trim();
    } catch (_) {
      aiEnrichment = null;
    }

    final insights = _mergeAiEnrichment(generatedInsights, aiEnrichment);

    chart = BirthChart(
      id: chart.id,
      profile: chart.profile,
      sun: chart.sun,
      moon: chart.moon,
      rising: chart.rising,
      planets: chart.planets,
      houses: chart.houses,
      aspects: chart.aspects,
      elementBalance: chart.elementBalance,
      dominantEnergy: chart.dominantEnergy,
      lifeThemes: themes,
      insights: insights,
      generatedAt: chart.generatedAt,
      precision: chart.precision,
    );

    await _repository.save(BirthChartRecordMapper.toRecord(chart));

    return BirthChartExperienceResult(chart: chart);
  }

  Future<BirthChart?> loadSaved() async {
    final record = await _repository.getLatest();
    if (record == null) return null;
    return BirthChartRecordMapper.fromRecord(record);
  }

  List<ChartInsight> _mergeAiEnrichment(
    List<ChartInsight> insights,
    String? aiText,
  ) {
    if (aiText == null || aiText.isEmpty) return insights;

    final sanitized = aiText
        .replaceAll(RegExp('kesinlikle|mutlaka|kader', caseSensitive: false), '…');

    return [
      for (final insight in insights)
        if (insight.kind == ChartInsightKind.corePersonality)
          ChartInsight(
            kind: insight.kind,
            title: insight.title,
            body: '${insight.body}\n\n$sanitized',
            glossaryTerm: insight.glossaryTerm,
            glossaryExplanation: insight.glossaryExplanation,
          )
        else
          insight,
    ];
  }
}
