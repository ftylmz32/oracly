/// OR-1140 — Rule registry — loads and resolves rule sets by engine.
library;

import 'rule_set.dart';

abstract class RuleRegistry {
  RuleSet? getRuleSet(String engineId);
  void register(RuleSet ruleSet);
  List<String> get registeredEngines;
}

class InMemoryRuleRegistry implements RuleRegistry {
  final Map<String, RuleSet> _sets = {};

  @override
  RuleSet? getRuleSet(String engineId) => _sets[engineId];

  @override
  void register(RuleSet ruleSet) => _sets[ruleSet.engine] = ruleSet;

  @override
  List<String> get registeredEngines => _sets.keys.toList();
}
