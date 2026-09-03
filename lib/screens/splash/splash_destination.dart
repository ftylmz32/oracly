/// Production destination after splash — never a placeholder Home.
library;

import 'package:flutter/material.dart';

import '../../core/data/datasources/local_storage.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/navigation/oracly_navigation.dart';

abstract final class SplashDestination {
  SplashDestination._();

  static const midnight = Color(0xFF07050D);

  /// Completed -> Home shell. Incomplete -> Onboarding.
  ///
  /// A saved setup draft must never skip onboarding. [OnboardingScreen]
  /// restores and resumes the draft itself.
  static Widget build({
    required bool onboardingCompleted,
    // Ignored: callers pass storage for a stable splash API. Draft restore
    // lives in OnboardingScreen — do not route Home from an incomplete draft.
    required LocalStorage storage,
  }) {
    final Widget page = onboardingCompleted
        ? const OraclyAppShell()
        : const OnboardingScreen();
    return ColoredBox(color: midnight, child: page);
  }

  /// Instant commit after in-place bridge — no second animated splash.
  static void commitRoute(BuildContext context, Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => destination,
      ),
    );
  }
}