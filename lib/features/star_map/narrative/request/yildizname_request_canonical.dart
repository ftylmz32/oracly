/// Canonical sorted JSON for semantic fingerprinting.
library;

import 'dart:convert';

import 'yildizname_narrative_request.dart';

abstract final class YildiznameRequestCanonical {
  YildiznameRequestCanonical._();

  /// Semantic canonical map — no attempt, owner, or birth data.
  static Map<String, dynamic> toMap(YildiznameNarrativeRequest request) {
    return _sortDeep(request.toProviderJson()) as Map<String, dynamic>;
  }

  static String encode(YildiznameNarrativeRequest request) {
    return jsonEncode(toMap(request));
  }

  /// Facts-only canonical (excludes discoveryThemes) for invariance tests.
  static String encodeFactsOnly(YildiznameNarrativeRequest request) {
    final map = Map<String, dynamic>.from(toMap(request));
    map.remove('discoveryThemes');
    return jsonEncode(_sortDeep(map));
  }

  static Object? _sortDeep(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: _sortDeep(v[k])};
    }
    if (v is List) return [for (final e in v) _sortDeep(e)];
    return v;
  }
}
