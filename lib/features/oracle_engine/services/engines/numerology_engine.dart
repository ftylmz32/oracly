/// OR-1140 — Numerology oracle engine.
library;

import '../../calculators/numerology_calculator.dart';
import '../../core/engine_contract.dart';
import '../../core/oracle_context.dart';
import '../../core/oracle_engine_type.dart';
import '../../core/oracle_result.dart';
import '../../data/copy_resolver.dart';
import '../../domain/numerology_engine_input.dart';
import '../../rules/rule_context.dart';
import '../../rules/rule_engine.dart';
import '../../rules/rule_registry.dart';

class NumerologyEngine implements OracleEngine<NumerologyEngineInput, NumerologyReading> {
  NumerologyEngine({
    required this.calculator,
    required this.ruleEngine,
    required this.ruleRegistry,
    CopyResolver? copyResolver,
  }) : copyResolver = copyResolver ?? KeyPassthroughCopyResolver();

  final NumerologyCalculator calculator;
  final RuleEngine ruleEngine;
  final RuleRegistry ruleRegistry;
  final CopyResolver copyResolver;

  @override
  OracleEngineType get type => OracleEngineType.numerology;

  @override
  Future<OracleResult<NumerologyReading>> execute({
    required NumerologyEngineInput input,
    required OracleContext context,
  }) async {
    final lifePath = calculator.lifePathNumber(input.birthDate);
    final nameNum =
        input.fullName != null ? calculator.nameNumber(input.fullName!) : null;

    final reading = NumerologyReading(
      id: 'num_${context.sessionId}_${context.timestamp.millisecondsSinceEpoch}',
      lifePathNumber: lifePath,
      nameNumber: nameNum,
      createdAt: context.timestamp,
    );

    final ruleSet = ruleRegistry.getRuleSet('numerology')!;
    final sections = ruleEngine.evaluate(
      context: RuleContext(facts: reading.toFacts(), locale: context.locale),
      ruleSet: ruleSet,
      resolveCopy: copyResolver.resolve,
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
