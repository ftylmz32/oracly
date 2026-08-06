/// OR-1140 — Configurable rule definition — no embedded business logic.
library;

import 'rule_condition.dart';

class RuleDefinition {
  const RuleDefinition({
    required this.id,
    required this.condition,
    required this.outcome,
    this.priority = 0,
    this.enabled = true,
  });

  final String id;
  final RuleCondition condition;
  final Map<String, dynamic> outcome;
  final int priority;
  final bool enabled;

  factory RuleDefinition.fromMap(Map<String, dynamic> map) {
    return RuleDefinition(
      id: map['id'] as String,
      condition: RuleCondition.parse(map['when'] as String),
      outcome: Map<String, dynamic>.from(map['outcome'] as Map),
      priority: map['priority'] as int? ?? 0,
      enabled: map['enabled'] as bool? ?? true,
    );
  }
}

class RuleSet {
  const RuleSet({
    required this.id,
    required this.engine,
    required this.rules,
    this.version = '1.0.0',
  });

  final String id;
  final String engine;
  final String version;
  final List<RuleDefinition> rules;

  factory RuleSet.fromMap(Map<String, dynamic> map) {
    final rulesRaw = map['rules'] as List<dynamic>? ?? [];
    return RuleSet(
      id: map['id'] as String,
      engine: map['engine'] as String,
      version: map['version'] as String? ?? '1.0.0',
      rules: rulesRaw
          .map((e) => RuleDefinition.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
