/// OR-1140 — Dream oracle engine.
library;

import '../../calculators/dream_symbol_calculator.dart';
import '../../core/engine_contract.dart';
import '../../core/oracle_context.dart';
import '../../core/oracle_engine_type.dart';
import '../../core/oracle_result.dart';
import '../../domain/dream_engine_input.dart';
import '../../interpreters/dream_interpreter.dart';
import '../../models/dream_reading.dart';
import '../../rules/rule_context.dart';
import '../../rules/rule_registry.dart';

class DreamEngine implements OracleEngine<DreamEngineInput, DreamReading> {
  DreamEngine({
    required this.symbolCalculator,
    required this.interpreter,
    required this.ruleRegistry,
  });

  final DreamSymbolCalculator symbolCalculator;
  final DreamInterpreter interpreter;
  final RuleRegistry ruleRegistry;

  @override
  OracleEngineType get type => OracleEngineType.dream;

  @override
  Future<OracleResult<DreamReading>> execute({
    required DreamEngineInput input,
    required OracleContext context,
  }) async {
    final symbols = symbolCalculator.categorize(input.rawText);
    final reading = DreamReading(
      id: 'dream_${context.sessionId}_${context.timestamp.millisecondsSinceEpoch}',
      rawText: input.rawText,
      symbols: symbols,
      emotions: input.emotions,
      createdAt: context.timestamp,
    );

    final ruleSet = ruleRegistry.getRuleSet('dream')!;
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
