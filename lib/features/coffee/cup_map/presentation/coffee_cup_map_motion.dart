/// Fincan Haritası motion: short, quiet, one-shot. Nothing loops except the
/// loading glint, which rests on reduced-motion and constrained devices.
/// Every duration collapses to zero when the OS asks for less motion.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_reduced_motion.dart';

abstract final class CoffeeCupMapMotion {
  CoffeeCupMapMotion._();

  /// Same curve as the app's immersive page enter.
  static const Curve ease = Cubic(0.22, 0.74, 0.18, 1.0);
  static const Curve exit = Curves.easeInCubic;

  static const Duration routeIn = Duration(milliseconds: 520);
  static const Duration routeOut = Duration(milliseconds: 340);

  /// First reveal of the map: photo, then strip, then the rest.
  static const Duration reveal = Duration(milliseconds: 620);

  /// Photo crossfade between the three views.
  static const Duration photo = Duration(milliseconds: 260);
  static const Duration photoFirstFade = Duration(milliseconds: 240);

  static const Duration pinAppear = Duration(milliseconds: 300);
  static const Duration pinSelect = Duration(milliseconds: 200);
  static const Duration zoomReset = Duration(milliseconds: 380);
  static const Duration door = Duration(milliseconds: 420);

  static const Duration sheetIn = Duration(milliseconds: 380);
  static const Duration sheetOut = Duration(milliseconds: 240);

  static bool reduced(BuildContext context) => OraclyReducedMotion.of(context);

  static Duration of(BuildContext context, Duration normal) =>
      reduced(context) ? Duration.zero : normal;
}

/// Door → map: the page rises a few pixels out of the result screen while
/// fading in; on the way back it settles down and fades. No motion at all
/// when reduced motion is on.
Route<T> coffeeCupMapRoute<T>(BuildContext context, Widget page) {
  final still = CoffeeCupMapMotion.reduced(context);
  return PageRouteBuilder<T>(
    transitionDuration: still ? Duration.zero : CoffeeCupMapMotion.routeIn,
    reverseTransitionDuration:
        still ? Duration.zero : CoffeeCupMapMotion.routeOut,
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: CoffeeCupMapMotion.ease,
        reverseCurve: CoffeeCupMapMotion.exit,
      );
      // Opaque within the first half, so the result screen never shows
      // through the photo; the lift and scale carry on to the end.
      final opacity = CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
      );
      return FadeTransition(
        opacity: opacity,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 16 * (1 - curved.value)),
            child: Transform.scale(
              scale: 0.975 + 0.025 * curved.value,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
