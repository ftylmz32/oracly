/// OR-1140 — Base interpreter delegating to rule engine.
library;

import '../data/copy_resolver.dart';
import '../interpreters/interpreter_contract.dart';
import '../rules/rule_context.dart';
import '../rules/rule_engine.dart';
import '../rules/rule_set.dart';
import '../core/oracle_result.dart';

abstract class RuleDrivenInterpreter<T> implements OracleInterpreter<T> {
  RuleDrivenInterpreter({
    required this.ruleEngine,
    CopyResolver? copyResolver,
  }) : copyResolver = copyResolver ?? KeyPassthroughCopyResolver();

  final RuleEngine ruleEngine;
  final CopyResolver copyResolver;

  Map<String, dynamic> buildFacts(T reading);

  @override
  List<InterpretationSection> interpret({
    required T reading,
    required RuleContext context,
    required RuleSet ruleSet,
  }) {
    final merged = RuleContext(
      facts: {...context.facts, ...buildFacts(reading)},
      locale: context.locale,
      computed: context.computed,
    );
    return ruleEngine.evaluate(
      context: merged,
      ruleSet: ruleSet,
      resolveCopy: copyResolver.resolve,
    );
  }
}
