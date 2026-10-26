/// Deterministic screen positions for genuine persisted reading records.
///
/// Does not generate inferred stars, relationships or readings. The caller
/// decides which persisted entries may be shown.
library;

import 'dart:math' as math;

/// Normalized point between 0.0 and 1.0, independent of viewport dimensions.
class EvrenimPosition {
  const EvrenimPosition(this.x, this.y);

  final double x;
  final double y;
}

abstract final class EvrenimConstellationLayout {
  EvrenimConstellationLayout._();

  /// Stable across app restarts, list order changes and new records.
  /// The kind is part of the key, since two feature stores may reuse IDs.
  static EvrenimPosition forReading({
    required String kind,
    required String id,
  }) {
    final key = '${kind.trim()}:${id.trim()}';
    final angleValue = _fnv32('angle:$key') / 0xffffffff;
    final radialValue = _fnv32('radius:$key') / 0xffffffff;
    final angle = 2 * math.pi * angleValue;
    // A bounded disk keeps tap targets away from the very edge.
    final radius = 0.12 + 0.31 * math.sqrt(radialValue);
    return EvrenimPosition(
      0.5 + radius * math.cos(angle),
      0.5 + radius * math.sin(angle),
    );
  }

  static int _fnv32(String text) {
    var hash = 0x811c9dc5;
    for (final codeUnit in text.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
