/// Home-only bottom clearance - avoids double-counting the shell nav.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';

/// Clears the floating bottom nav without stacking nav chrome twice.
///
/// The app shell uses Scaffold(extendBody: true) + bottom bar. Flutter then
/// injects the bar full height into [MediaQuery.padding].bottom.
/// [AppLayout.scrollBottomInset] also adds nav height + margin, which creates
/// a large empty band under Premium on real devices.
///
/// Isolated Home pumps (no shell bar) still see system safe-area only, so
/// this helper adds explicit bar chrome in that case.
abstract final class HomeMasterBottomInset {
  HomeMasterBottomInset._();

  static double resolve(
    BuildContext context, {
    bool scaffoldResizesForKeyboard = true,
  }) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard > 0) {
      final overlay = AppLayout.navBarHeight +
          AppLayout.navBarMarginBottom +
          AppLayout.contentBottomBreath;
      if (scaffoldResizesForKeyboard) return overlay;
      return keyboard + overlay;
    }

    final paddingBottom = MediaQuery.paddingOf(context).bottom;
    const barChrome =
        AppLayout.navBarHeight + AppLayout.navBarMarginBottom;
    final cleared = paddingBottom >= barChrome
        ? paddingBottom
        : barChrome + paddingBottom;
    return cleared + AppLayout.contentBottomBreath;
  }
}
