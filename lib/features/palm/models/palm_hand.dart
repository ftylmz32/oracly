/// Which palm the user photographed.
library;

import '../copy/palm_copy.dart';

enum PalmHand {
  right,
  left;

  /// Presentation only. Persisted identity stays [name] (`left` / `right`).
  String get label =>
      this == PalmHand.right ? PalmCopy.rightHand : PalmCopy.leftHand;

  /// Server `_handSide`. Unknown values stay unknown.
  static PalmHand? fromWire(Object? raw) {
    if (raw == PalmHand.left.name) return PalmHand.left;
    if (raw == PalmHand.right.name) return PalmHand.right;
    return null;
  }
}
