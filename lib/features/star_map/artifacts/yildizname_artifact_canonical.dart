/// Deterministic deep-sort for artifact integrity / digests.
library;

import 'dart:convert';

abstract final class YildiznameArtifactCanonical {
  YildiznameArtifactCanonical._();

  static Object? sortDeep(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: sortDeep(v[k])};
    }
    if (v is List) return [for (final e in v) sortDeep(e)];
    return v;
  }

  static String encode(Object? value) => jsonEncode(sortDeep(value));
}
