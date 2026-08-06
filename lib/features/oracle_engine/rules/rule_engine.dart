/// OR-1140 — Config-driven rule evaluation engine.
library;

import '../core/oracle_result.dart';
import 'rule_context.dart';
import 'rule_outcome.dart';
import 'rule_set.dart';

abstract class RuleEngine {
  List<InterpretationSection> evaluate({
    required RuleContext context,
    required RuleSet ruleSet,
    required String Function(String key, String locale) resolveCopy,
  });
}

class ConfigurableRuleEngine implements RuleEngine {
  @override
  List<InterpretationSection> evaluate({
    required RuleContext context,
    required RuleSet ruleSet,
    required String Function(String key, String locale) resolveCopy,
  }) {
    final sorted = [...ruleSet.rules]
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final sections = <InterpretationSection>[];
    final seenKeys = <String>{};

    for (final rule in sorted) {
      if (!rule.enabled) continue;
      if (!rule.condition.evaluate(context)) continue;

      final outcome = RuleOutcome.fromMap(rule.outcome);
      if (seenKeys.contains(outcome.sectionKey)) continue;
      seenKeys.add(outcome.sectionKey);

      sections.add(
        InterpretationSection(
          key: outcome.sectionKey,
          title: resolveCopy(outcome.titleKey, context.locale),
          content: resolveCopy(outcome.contentKey, context.locale),
          weight: outcome.weight,
          tags: outcome.tags,
        ),
      );
    }

    return sections;
  }
}
