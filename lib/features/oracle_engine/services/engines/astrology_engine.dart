/// OR-1140 — Astrology oracle engine.
library;

import '../../core/engine_contract.dart';
import '../../core/oracle_context.dart';
import '../../core/oracle_engine_type.dart';
import '../../core/oracle_result.dart';
import '../../domain/astrology_engine_input.dart';
import '../../interpreters/astrology_interpreter.dart';
import '../../models/horoscope_reading.dart';
import '../../rules/rule_context.dart';
import '../../rules/rule_registry.dart';

class AstrologyEngine
    implements OracleEngine<AstrologyEngineInput, HoroscopeReading> {
  AstrologyEngine({
    required this.interpreter,
    required this.ruleRegistry,
  });

  final AstrologyInterpreter interpreter;
  final RuleRegistry ruleRegistry;

  @override
  OracleEngineType get type => OracleEngineType.astrology;

  @override
  Future<OracleResult<HoroscopeReading>> execute({
    required AstrologyEngineInput input,
    required OracleContext context,
  }) async {
    final reading = HoroscopeReading(
      id: 'astro_${context.sessionId}_${context.timestamp.millisecondsSinceEpoch}',
      sunSign: input.sunSign,
      features: input.features,
      createdAt: context.timestamp,
      moonSign: input.moonSign,
      ascendant: input.ascendant,
    );

    final ruleSet = ruleRegistry.getRuleSet('astrology')!;
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
