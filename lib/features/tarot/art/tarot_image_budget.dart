/// Tight image-cache window while the tarot ritual is open.
library;

import 'package:flutter/painting.dart';

abstract final class TarotImageBudget {
  TarotImageBudget._();

  static const liveLimit = 28;
  static const byteLimit = 40 * 1024 * 1024;

  static int _prevCount = 1000;
  static int _prevBytes = 100 << 20;
  static var _held = false;

  static void enter() {
    final cache = PaintingBinding.instance.imageCache;
    if (!_held) {
      _prevCount = cache.maximumSize;
      _prevBytes = cache.maximumSizeBytes;
      _held = true;
    }
    cache.maximumSize = liveLimit;
    cache.maximumSizeBytes = byteLimit;
  }

  static void leave() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    if (_held) {
      cache.maximumSize = _prevCount;
      cache.maximumSizeBytes = _prevBytes;
      _held = false;
    }
  }
}
