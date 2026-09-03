/// Portrait-first phones; tablets keep platform orientations.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Locks phone-class viewports to upright portrait for release UX.
abstract final class OraclyPhoneOrientation {
  OraclyPhoneOrientation._();

  /// Material phone/tablet breakpoint (logical shortest side).
  static const double phoneShortestSideMax = 600;

  static Future<void> lockPhonesToPortrait() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (!_isPhoneClassViewport()) return;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  static bool _isPhoneClassViewport() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return true;
    final view = views.first;
    final dpr = view.devicePixelRatio;
    if (dpr <= 0) return true;
    final shortest = view.physicalSize.shortestSide / dpr;
    return shortest < phoneShortestSideMax;
  }
}