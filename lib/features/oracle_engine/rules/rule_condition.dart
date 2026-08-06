/// OR-1140 — Declarative condition parser for rule matching.
library;

import 'rule_context.dart';

sealed class RuleCondition {
  const RuleCondition();

  bool evaluate(RuleContext context);

  static RuleCondition parse(String expression) {
    final trimmed = expression.trim();
    if (trimmed == 'always') return const AlwaysCondition();

    if (trimmed.contains('==')) {
      final parts = trimmed.split('==').map((e) => e.trim()).toList();
      return EqualsCondition(parts[0], _parseValue(parts[1]));
    }
    if (trimmed.contains('>=')) {
      final parts = trimmed.split('>=').map((e) => e.trim()).toList();
      return CompareCondition(parts[0], '>=', double.parse(parts[1]));
    }
    if (trimmed.contains('in')) {
      final match = RegExp(r'^(\w+(?:\.\w+)*)\s+in\s+\[(.+)\]$').firstMatch(trimmed);
      if (match != null) {
        final path = match.group(1)!;
        final values = match.group(2)!
            .split(',')
            .map((e) => e.trim().replaceAll("'", '').replaceAll('"', ''))
            .toList();
        return InCondition(path, values);
      }
    }
    if (trimmed.startsWith('exists ')) {
      return ExistsCondition(trimmed.substring(7).trim());
    }

    return FeatureFlagCondition(trimmed);
  }

  static dynamic _parseValue(String raw) {
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    final number = num.tryParse(raw);
    if (number != null) return number;
    return raw.replaceAll("'", '').replaceAll('"', '');
  }
}

final class AlwaysCondition extends RuleCondition {
  const AlwaysCondition();
  @override
  bool evaluate(RuleContext context) => true;
}

final class EqualsCondition extends RuleCondition {
  const EqualsCondition(this.path, this.expected);
  final String path;
  final dynamic expected;
  @override
  bool evaluate(RuleContext context) => context.get(path) == expected;
}

final class CompareCondition extends RuleCondition {
  const CompareCondition(this.path, this.operator, this.threshold);
  final String path;
  final String operator;
  final double threshold;
  @override
  bool evaluate(RuleContext context) {
    final value = context.get(path);
    if (value is! num) return false;
    return switch (operator) {
      '>=' => value >= threshold,
      '<=' => value <= threshold,
      '>' => value > threshold,
      '<' => value < threshold,
      _ => false,
    };
  }
}

final class InCondition extends RuleCondition {
  const InCondition(this.path, this.values);
  final String path;
  final List<String> values;
  @override
  bool evaluate(RuleContext context) {
    final value = context.get(path)?.toString();
    return value != null && values.contains(value);
  }
}

final class ExistsCondition extends RuleCondition {
  const ExistsCondition(this.path);
  final String path;
  @override
  bool evaluate(RuleContext context) => context.get(path) != null;
}

final class FeatureFlagCondition extends RuleCondition {
  const FeatureFlagCondition(this.flag);
  final String flag;
  @override
  bool evaluate(RuleContext context) {
    final features = context.get('features');
    if (features is List) return features.contains(flag);
    return context.get('feature.$flag') == true;
  }
}
