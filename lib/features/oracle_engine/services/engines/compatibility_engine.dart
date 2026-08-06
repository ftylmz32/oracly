/// OR-1140 — Compatibility oracle engine.
library;

import '../../calculators/compatibility_calculator.dart';
import '../../core/engine_contract.dart';
import '../../core/oracle_context.dart';
import '../../core/oracle_engine_type.dart';
import '../../core/oracle_result.dart';
import '../../data/copy_resolver.dart';
import '../../domain/compatibility_engine_input.dart';
import '../../models/compatibility_reading.dart';
import '../../rules/rule_context.dart';
import '../../rules/rule_engine.dart';
import '../../rules/rule_registry.dart';

class CompatibilityEngine
    implements OracleEngine<CompatibilityEngineInput, CompatibilityReading> {
  CompatibilityEngine({
    required this.calculator,
    required this.ruleEngine,
    required this.ruleRegistry,
    CopyResolver? copyResolver,
  }) : copyResolver = copyResolver ?? KeyPassthroughCopyResolver();

  final CompatibilityCalculator calculator;
  final RuleEngine ruleEngine;
  final RuleRegistry ruleRegistry;
  final CopyResolver copyResolver;

  @override
  OracleEngineType get type => OracleEngineType.compatibility;

  @override
  Future<OracleResult<CompatibilityReading>> execute({
    required CompatibilityEngineInput input,
    required OracleContext context,
  }) async {
    final dimensions = calculator.dimensionsFor(
      subjectA: input.subjectA,
      subjectB: input.subjectB,
      chartA: input.chartA,
      chartB: input.chartB,
    );
    final overall = calculator.overallScore(dimensions);

    final reading = CompatibilityReading(
      id: 'compat_${context.sessionId}_${context.timestamp.millisecondsSinceEpoch}',
      subjectA: input.subjectA,
      subjectB: input.subjectB,
      overallScore: overall,
      dimensions: dimensions,
      createdAt: context.timestamp,
    );

    final ruleSet = ruleRegistry.getRuleSet('compatibility')!;
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
