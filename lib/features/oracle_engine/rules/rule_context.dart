/// OR-1140 — Rule evaluation context — facts + metadata for rule matching.
library;

class RuleContext {
  RuleContext({
    required this.facts,
    this.locale = 'tr',
    Map<String, dynamic>? computed,
  }) : computed = computed ?? {};

  final Map<String, dynamic> facts;
  final String locale;
  final Map<String, dynamic> computed;

  RuleContext withComputed(String key, dynamic value) {
    return RuleContext(
      facts: facts,
      locale: locale,
      computed: {...computed, key: value},
    );
  }

  dynamic get(String path) {
    if (computed.containsKey(path)) return computed[path];
    return _resolvePath(facts, path);
  }

  dynamic _resolvePath(Map<String, dynamic> map, String path) {
    final parts = path.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is! Map) return null;
      current = current[part];
      if (current == null) return null;
    }
    return current;
  }
}
