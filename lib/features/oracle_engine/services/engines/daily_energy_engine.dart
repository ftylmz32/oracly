/// OR-1140 — Daily energy oracle engine.
library;

import '../../calculators/moon_phase_calculator.dart';
import '../../calculators/vibration_calculator.dart';
import '../../core/engine_contract.dart';
import '../../core/oracle_context.dart';
import '../../core/oracle_engine_type.dart';
import '../../core/oracle_result.dart';
import '../../domain/daily_energy_engine_input.dart';
import '../../interpreters/energy_interpreter.dart';
import '../../models/energy_reading.dart';
import '../../rules/rule_context.dart';
import '../../rules/rule_registry.dart';

class DailyEnergyEngine implements OracleEngine<DailyEnergyEngineInput, EnergyReading> {
  DailyEnergyEngine({
    required this.vibrationCalculator,
    required this.moonPhaseCalculator,
    required this.interpreter,
    required this.ruleRegistry,
  });

  final VibrationCalculator vibrationCalculator;
  final MoonPhaseCalculator moonPhaseCalculator;
  final EnergyInterpreter interpreter;
  final RuleRegistry ruleRegistry;

  @override
  OracleEngineType get type => OracleEngineType.dailyEnergy;

  @override
  Future<OracleResult<EnergyReading>> execute({
    required DailyEnergyEngineInput input,
    required OracleContext context,
  }) async {
    final vibration = vibrationCalculator.scoreFor(input.date);
    final moonPhase = moonPhaseCalculator.phaseFor(input.date);
    final moonLabel = moonPhaseCalculator.labelKeyFor(moonPhase);

    final reading = EnergyReading(
      id: 'energy_${context.sessionId}_${context.timestamp.millisecondsSinceEpoch}',
      date: input.date,
      features: input.features,
      vibrationScore: vibration,
      moonPhaseLabel: moonLabel,
      element: 'energy.element.${input.date.month % 4}',
      luckyNumber: (input.date.day + input.date.month) % 9 + 1,
      luckyColor: 'energy.color.${input.date.weekday}',
      luckyCrystal: 'energy.crystal.${moonPhase.name}',
      spiritMessageKey: 'energy.spirit.${input.date.weekday}',
    );

    final ruleSet = ruleRegistry.getRuleSet('dailyEnergy')!;
    final sections = interpreter.interpret(
      reading: reading,
      context: RuleContext(facts: reading.toFacts(), locale: context.locale),
      ruleSet: ruleSet,
    );

    return OracleResult(
      engine: type,
      readingId: reading.id,
      payload: reading,
      sections: sections,
      generatedAt: context.timestamp,
      ruleSetId: ruleSet.id,
    );
  }
}
