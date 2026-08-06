/// OR-050 — Daily Energy Details navigation.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../screens/daily_energy_details_screen.dart';

/// Opens the details screen with a premium shared-axis transition.
abstract final class DailyEnergyDetailsRoute {
  DailyEnergyDetailsRoute._();

  static Future<void> open(
    BuildContext context, {
    String? summary,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: false,
        opaque: true,
        transitionDuration: AppDuration.medium,
        reverseTransitionDuration: AppDuration.normal,
        pageBuilder: (context, animation, secondaryAnimation) {
          return DailyEnergyDetailsScreen(summary: summary);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.045),
            end: Offset.zero,
          ).animate(curved);
          final scale = Tween<double>(begin: 0.985, end: 1.0).animate(curved);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: scale,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
