/// OR-1140 — Engine factory — wires all modules with dependencies.
library;

import '../calculators/compatibility_calculator.dart';
import '../calculators/dream_symbol_calculator.dart';
import '../calculators/moon_phase_calculator.dart';
import '../calculators/numerology_calculator.dart';
import '../calculators/tarot_spread_calculator.dart';
import '../calculators/vibration_calculator.dart';
import '../core/engine_contract.dart';
import '../core/oracle_engine_type.dart';
import '../data/copy_resolver.dart';
import '../data/default_rule_sets.dart';
import '../interpreters/astrology_interpreter.dart';
import '../interpreters/dream_interpreter.dart';
import '../interpreters/energy_interpreter.dart';
import '../interpreters/tarot_interpreter.dart';
import '../rules/rule_engine.dart';
import '../rules/rule_registry.dart';
import 'engines/astrology_engine.dart';
import 'engines/compatibility_engine.dart';
import 'engines/daily_energy_engine.dart';
import 'engines/dream_engine.dart';
import 'engines/numerology_engine.dart';
import 'engines/tarot_engine.dart';

abstract final class OracleEngineFactory {
  OracleEngineFactory._();

  static OracleEngineRegistry buildRegistry({
    RuleRegistry? ruleRegistry,
    RuleEngine? ruleEngine,
    CopyResolver? copyResolver,
  }) {
    final engineRegistry = DefaultOracleEngineRegistry();
    final rules = ruleRegistry ?? InMemoryRuleRegistry();
    if (ruleRegistry == null) {
      for (final set in DefaultRuleSets.all) {
        rules.register(set);
      }
    }

    final engine = ruleEngine ?? ConfigurableRuleEngine();
    final copy = copyResolver ?? KeyPassthroughCopyResolver();

    engineRegistry.register(
      OracleEngineType.tarot,
      TarotEngine(
        spreadCalculator: ConfigurableTarotSpreadCalculator(),
        interpreter: TarotInterpreter(ruleEngine: engine, copyResolver: copy),
        ruleRegistry: rules,
      ),
    );
    engineRegistry.register(
      OracleEngineType.dream,
      DreamEngine(
        symbolCalculator: LexiconDreamSymbolCalculator(),
        interpreter: DreamInterpreter(ruleEngine: engine, copyResolver: copy),
        ruleRegistry: rules,
      ),
    );
    engineRegistry.register(
      OracleEngineType.astrology,
      AstrologyEngine(
        interpreter: AstrologyInterpreter(ruleEngine: engine, copyResolver: copy),
        ruleRegistry: rules,
      ),
    );
    engineRegistry.register(
      OracleEngineType.dailyEnergy,
      DailyEnergyEngine(
        vibrationCalculator: DateVibrationCalculator(),
        moonPhaseCalculator: AstronomicalMoonPhaseCalculator(),
        interpreter: EnergyInterpreter(ruleEngine: engine, copyResolver: copy),
        ruleRegistry: rules,
      ),
    );
    engineRegistry.register(
      OracleEngineType.compatibility,
      CompatibilityEngine(
        calculator: WeightedCompatibilityCalculator(),
        ruleEngine: engine,
        ruleRegistry: rules,
        copyResolver: copy,
      ),
    );
    engineRegistry.register(
      OracleEngineType.numerology,
      NumerologyEngine(
        calculator: PythagoreanNumerologyCalculator(),
        ruleEngine: engine,
        ruleRegistry: rules,
        copyResolver: copy,
      ),
    );

    return engineRegistry;
  }
}
