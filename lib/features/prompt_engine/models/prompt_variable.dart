/// OR-1160 — Template variable definition and runtime value.
library;

enum PromptVariableType {
  string,
  number,
  boolean,
  list,
  object,
}

class PromptVariable {
  const PromptVariable({
    required this.key,
    required this.type,
    this.required = true,
    this.description,
    this.maxLength,
    this.min,
    this.max,
    this.defaultValue,
    this.allowedValues,
  });

  final String key;
  final PromptVariableType type;
  final bool required;
  final String? description;
  final int? maxLength;
  final num? min;
  final num? max;
  final dynamic defaultValue;
  final List<String>? allowedValues;

  bool validateValue(dynamic value) {
    if (value == null) return !required;
    switch (type) {
      case PromptVariableType.string:
        if (value is! String) return false;
        if (maxLength != null && value.length > maxLength!) return false;
        if (allowedValues != null && !allowedValues!.contains(value)) {
          return false;
        }
        return true;
      case PromptVariableType.number:
        if (value is! num) return false;
        if (min != null && value < min!) return false;
        if (max != null && value > max!) return false;
        return true;
      case PromptVariableType.boolean:
        return value is bool;
      case PromptVariableType.list:
        return value is List;
      case PromptVariableType.object:
        return value is Map;
    }
  }
}

class PromptVariableValue {
  const PromptVariableValue({
    required this.key,
    required this.value,
  });

  final String key;
  final dynamic value;
}
