/// Production destination after splash — never a placeholder Home.
library;

import 'package:flutter/material.dart';

import '../../core/data/datasources/local_storage.dart';
import '../../features/onboarding/data/onboarding_setup_draft_store.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/navigation/oracly_navigation.dart';

abstract final class SplashDestination {
  SplashDestination._();

  static const midnight = Color(0xFF07050D);

  static Widget build({
    required bool onboardingCompleted,
    required LocalStorage storage,
  }) {
    final Widget page;
    if (onboardingCompleted) {
      page = const OraclyAppShell();
    } else if (OnboardingSetupDraftStore(storage).load() != null) {
      page = const OraclyAppShell(initialTab: OraclyTab.home);
    } else {
      page = const OnboardingScreen();
    }
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
