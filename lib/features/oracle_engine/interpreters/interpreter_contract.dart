/// OR-1140 — Interpreter contract.
library;

import '../core/oracle_result.dart';
import '../rules/rule_context.dart';
import '../rules/rule_set.dart';

abstract class OracleInterpreter<T> {
  String get engineId;

  List<InterpretationSection> interpret({
    required T reading,
    required RuleContext context,
    required RuleSet ruleSet,
  });
}
