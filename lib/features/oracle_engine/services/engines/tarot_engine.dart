/// OR-1140 — Tarot oracle engine.
library;

import '../../calculators/tarot_spread_calculator.dart';
import '../../core/engine_contract.dart';
import '../../core/oracle_context.dart';
import '../../core/oracle_engine_type.dart';
import '../../core/oracle_result.dart';
import '../../domain/tarot_engine_input.dart';
import '../../interpreters/tarot_interpreter.dart';
import '../../models/tarot_reading.dart';
import '../../rules/rule_context.dart';
import '../../rules/rule_registry.dart';

class TarotEngine implements OracleEngine<TarotEngineInput, TarotReading> {
  TarotEngine({
    required this.spreadCalculator,
    required this.interpreter,
    required this.ruleRegistry,
  });

  final TarotSpreadCalculator spreadCalculator;
  final TarotInterpreter interpreter;
  final RuleRegistry ruleRegistry;

  @override
  OracleEngineType get type => OracleEngineType.tarot;

  @override
  Future<OracleResult<TarotReading>> execute({
    required TarotEngineInput input,
    required OracleContext context,
  }) async {
    final positions = spreadCalculator.positionsFor(input.spreadType);
    final cards = [
      for (var i = 0; i < positions.length && i < input.cardIds.length; i++)
        TarotCardDraw(
          cardId: input.cardIds[i],
          positionIndex: positions[i].index,
          positionLabel: positions[i].labelKey,
          isReversed: input.reversedIndices.contains(i),
        ),
    ];

    final reading = input.toReading(
      id: 'tarot_${context.sessionId}_${context.timestamp.millisecondsSinceEpoch}',
      cards: cards,
      createdAt: context.timestamp,
    );

    final ruleSet = ruleRegistry.getRuleSet('tarot')!;
    final ruleContext = RuleContext(facts: reading.toFacts(), locale: context.locale);
    final sections = interpreter.interpret(
      reading: reading,
      context: ruleContext,
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
