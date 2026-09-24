/// Phase 6E.1 — recursive deep-freeze for shadow wire snapshots (QA only).
library;

/// Pure recursive freeze. Does not mutate the input tree in place.
Object? deepFreezeWire(Object? value) {
  if (value is Map) {
    final frozen = <String, Object?>{
      for (final e in value.entries) '${e.key}': deepFreezeWire(e.value),
    };
    return Map<String, Object?>.unmodifiable(frozen);
  }
  if (value is List) {
    return List<Object?>.unmodifiable([
      for (final e in value) deepFreezeWire(e),
    ]);
  }
  return value;
}

Map<String, Object?> deepFreezeWireMap(Map<String, Object?> payload) {
  return deepFreezeWire(payload)! as Map<String, Object?>;
}
