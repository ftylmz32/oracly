/// Temporary splash timing logs — remove after release verification.
library;

import 'package:flutter/foundation.dart';

abstract final class SplashStartupLog {
  SplashStartupLog._();

  static final _sw = Stopwatch()..start();

  static void mark(String tag) {
    debugPrint('SPLASH_TIMING ${_sw.elapsedMilliseconds}ms $tag');
  }
}
