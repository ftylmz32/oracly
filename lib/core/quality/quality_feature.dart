/// Seven measured experiences — wire names only, never user text.
library;

enum QualityFeature {
  coffee,
  palm,
  tarot,
  dream,
  astrology,
  starMap,
  companion;

  String get wire => name;

  static QualityFeature? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}
